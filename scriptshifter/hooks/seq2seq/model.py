# original code: https://machinelearningmastery.com/building-a-seq2seq-model-
# with-attention-for-language-translation/
# Heavily modified by hand & with AI assistant to support S2R transliteration.

import csv
import random
from logging import getLogger
from os import makedirs, path
from shutil import copy
from unicodedata import normalize

import torch
import torch.nn as nn
import torch.nn.functional as F
import torch.optim as optim
import tokenizers
import tqdm

# Script-specific modules.
# Arabic
from piraye import NormalizerBuilder as AraNormalizer
# Persian
from shekar import Normalizer as PerNormalizer


# Data root folder.
DATA_ROOT = path.join(path.dirname(__file__), "data")

# Code point range for all Arabic scripts.
ARA_CP = (
    ("\u0600", "\u06FF"),  # Arabic
    ("\u0750", "\u077F"),  # Arabic Supplement
    ("\u08A0", "\u08FF"),  # Arabic Extended-A
    ("\u0870", "\u089F"),  # Arabic Extended-B
    ("\uFB50", "\uFDFF"),  # Arabic Presentation Forms-A
    ("\uFE70", "\uFEFF"),  # Arabic Presentation Forms-B
    ("\U00010EC0", "\U00010EFF"),  # Arabic Extended-C
    ("\U0001EE00", "\U0001EEFF"),  # Arabic Mathematical Alphabetic Symbols
)

# Valid code point ranges for each language.
# The values are 2D tuples, with the inner elements being 2-character tuples
# representing a code point range (min, max).
CP_RANGE = {
    # Space (\u0020) is the lowest printable code point.
    "latin": (("\u0020", "\u036F"),),
    "ara": ARA_CP,
    "per": ARA_CP,
}

DEVICE = torch.device('cuda:0' if torch.cuda.is_available() else 'cpu')

# Tokens.
SOS_TOK = "[start]"
EOS_TOK = "[end]"
PAD_TOK = "[pad]"
SEP_TOK = "[sep]"
CLS_TOK = "[cls]"
UNK_TOK = "[unk]"


# Model parameters, per language.
PARAMS = {
    "ara": {
        # Tokenizer parameters for script only.
        "vocab_size": 16000,
        # Encoder and decoder parameters.
        "emb_dim": 384,
        "dropout": 0.1,
        "n_layers": 1,
        "lr": 2e-4,
        "weight_decay": 1e-5,
        "grad_clip": 1.5,
        # Training parameters.
        "n_epochs": 20,
        "warmup": 4,
        "batch_size": 16,
    },
    "per": {
        "vocab_size": 16000,
        "emb_dim": 256,
        "dropout": 0.0,  # for debug. Set to 0.2 for real trainig.
        "n_layers": 1,
        "lr": 4e-4,
        "weight_decay": 1e-5,
        "grad_clip": 0.5,
        "n_epochs": 50,
        "warmup": 2,
        "batch_size": 32,
    },
}

# Filter out outlier-length pairs to bound memory per batch.
MAX_SRC_CHARS = 300
MAX_TGT_CHARS = MAX_SRC_CHARS * 1.33

logger = getLogger(__name__)


def _normalize_ara(input):
    normalizer = (AraNormalizer()
            .remove_extra_spaces()
            .space_normal()
            .digit_ar()
            .punctuation_ar()
            .build())

    return normalizer.normalize(input)[0]


normalize_fn = {
    "ara": _normalize_ara,
    "per": PerNormalizer(),
}


#
# Read raw data
#

def _in_range(s, lang):
    """
    Whether a string is within a character range.

    Returns true or false, whether at least one character in the string is
    within the code point range defined by CP_RANGE for the given language.
    """
    cp_range = CP_RANGE.get(lang, CP_RANGE["latin"])

    for ch in s:
        for min_cp, max_cp in cp_range:
            if ch >= min_cp and ch <= max_cp:
                return True
    return False


def _levenshtein(a, b):
    """
    Edit distance between two sequences (strings or lists).

    O(len(a)*len(b)).
    """
    if a == b:
        return 0
    if not a:
        return len(b)
    if not b:
        return len(a)
    prev = list(range(len(b) + 1))
    for i, ai in enumerate(a, 1):
        curr = [i] + [0] * len(b)
        for j, bj in enumerate(b, 1):
            cost = 0 if ai == bj else 1
            curr[j] = min(
                curr[j - 1] + 1,        # insertion
                prev[j] + 1,            # deletion
                prev[j - 1] + cost,     # substitution
            )
        prev = curr
    return prev[-1]


def read_langs(script, split="train"):
    logger.info(f"Reading sources ({split})...")
    src_path = path.join(DATA_ROOT, "source", script, f"{split}.csv")
    norm_fpath = path.join(DATA_ROOT, "normalized", script, f"{split}.csv")
    makedirs(path.dirname(norm_fpath), exist_ok=True)

    if path.isfile(norm_fpath):
        logger.debug("Reusing cached token pairs.")
        with open(norm_fpath, newline="") as fh:
            reader = csv.reader(fh)
            pairs = [row for row in reader]
    else:
        # Read the file and split into lines
        with open(src_path, newline="") as fh:
            reader = csv.reader(fh)
            pairs = [
                (normalize_fn[script](row[0]), normalize("NFKC", row[1]))
                for row in reader
                if _in_range(row[0], script)
            ]
        pre_filter = len(pairs)
        pairs = [
            (s, r) for s, r in pairs
            if len(s) <= MAX_SRC_CHARS and len(r) <= MAX_TGT_CHARS
        ]
        dropped = pre_filter - len(pairs)
        if dropped:
            logger.debug(
                f"Filtered {dropped}/{pre_filter} ({split}) pairs "
                "over length cap."
            )

        with open(norm_fpath, "w", newline="") as fh:
            writer = csv.writer(fh)
            for line in pairs:
                writer.writerow(line)
        logger.debug(f"Wrote normalized token pairs to {norm_fpath}.")

    return pairs


#
# Tokenization
#

def tokenize(lang, code, vocab, level="bpe"):
    """Build or load a tokenizer.

    level="bpe": byte-level BPE with a 16k vocab — used for the script side.
    level="char": character-level vocab (~40 symbols) — used for the Roman
    output side, where graphemes align directly to characters and a small
    output vocab improves generalization for transliteration.
    """
    tok_datadir = path.join(DATA_ROOT, "tokenizer", lang)
    fname = path.join(tok_datadir, f"{code}_tokenizer.json")

    if path.exists(fname):
        logger.debug("Reused token data.")
        return tokenizers.Tokenizer.from_file(fname)

    if level == "char" or code == "rom":
        # Build vocab from observed characters plus specials.
        chars = sorted({c for s in vocab for c in s})
        char_vocab = {tok: i for i, tok in enumerate(
                [PAD_TOK, SOS_TOK, EOS_TOK, UNK_TOK] + chars)}
        tokenizer = tokenizers.Tokenizer(
                tokenizers.models.WordLevel(char_vocab, unk_token=UNK_TOK))
        # Split on every character so each char becomes a token.
        tokenizer.pre_tokenizer = tokenizers.pre_tokenizers.Split(
                pattern=tokenizers.Regex(""), behavior="isolated")
        tokenizer.decoder = tokenizers.decoders.Fuse()
        logger.debug("Generated character-level token data.")
    else:
        tokenizer = tokenizers.Tokenizer(tokenizers.models.BPE())
        tokenizer.pre_tokenizer = tokenizers.pre_tokenizers.ByteLevel(
                add_prefix_space=True)
        tokenizer.decoder = tokenizers.decoders.ByteLevel()
        trainer = tokenizers.trainers.BpeTrainer(
            vocab_size=PARAMS[lang]["vocab_size"],
            special_tokens=[SOS_TOK, EOS_TOK, PAD_TOK, UNK_TOK],
            show_progress=True
        )
        tokenizer.train_from_iterator(vocab, trainer=trainer)
        logger.debug("Generated BPE token data.")

    # Auto-add SOS/EOS at encode time so the dataset doesn't have to
    # string-wrap them (which would split under char-level tokenization).
    sos_id = tokenizer.token_to_id(SOS_TOK)
    eos_id = tokenizer.token_to_id(EOS_TOK)
    tokenizer.post_processor = tokenizers.processors.TemplateProcessing(
        single=f"{SOS_TOK} $A {EOS_TOK}",
        special_tokens=[(SOS_TOK, sos_id), (EOS_TOK, eos_id)],
    )
    tokenizer.enable_padding(
            pad_id=tokenizer.token_to_id(PAD_TOK), pad_token=PAD_TOK)
    makedirs(tok_datadir, exist_ok=True)
    tokenizer.save(fname)
    logger.debug("Saved token data cache.")

    return tokenizer


# Create PyTorch dataset for the BPE-encoded translation pairs
#
# Map-style dataset:
# https://docs.pytorch.org/docs/stable/data.html#map-style-datasets
class TransliterationDataset(torch.utils.data.Dataset):
    def __init__(self, text_pairs):
        self.text_pairs = text_pairs

    def __len__(self):
        return len(self.text_pairs)

    def __getitem__(self, idx):
        # SOS/EOS are added by the tokenizer's post-processor.
        return self.text_pairs[idx]


def get_collate_fn(scr_tokenizer, rom_tokenizer):
    def collate_fn(batch):
        scr_str, rom_str = zip(*batch)
        scr_enc = scr_tokenizer.encode_batch(scr_str, add_special_tokens=True)
        rom_enc = rom_tokenizer.encode_batch(rom_str, add_special_tokens=True)

        return (
            torch.tensor([enc.ids for enc in scr_enc]),
            torch.tensor([enc.ids for enc in rom_enc])
        )

    return collate_fn


def get_dataloaders(lang):
    train_pairs = read_langs(lang, "train")
    logger.debug("Loaded pairs.")
    # Tokenizers are fit on training data only
    scr_tokenizer = tokenize(lang, "scr", [x[0] for x in train_pairs])
    logger.debug("Tokenized script.")
    # Char-level for the Roman output: ~40-symbol vocab aligns to graphemes
    # and avoids BPE merges that don't correspond to script boundaries.
    rom_tokenizer = tokenize(lang, "rom", [x[1] for x in train_pairs])
    logger.debug("Tokenized Roman.")

    collate = get_collate_fn(scr_tokenizer, rom_tokenizer)
    train_loader = torch.utils.data.DataLoader(
            TransliterationDataset(train_pairs),
            batch_size=PARAMS[lang]["batch_size"], shuffle=True,
            collate_fn=collate,)
    logger.debug("Collated datasets.")

    dev_path = path.join(DATA_ROOT, "source", lang, "dev.csv")
    if path.exists(dev_path):
        dev_pairs = read_langs(lang, "dev")
        dev_loader = torch.utils.data.DataLoader(
                TransliterationDataset(dev_pairs),
                batch_size=PARAMS[lang]["batch_size"], shuffle=False,
                collate_fn=collate,)
    else:
        dev_loader = None
    logger.debug("Set up loaders.")

    return train_loader, dev_loader, scr_tokenizer, rom_tokenizer


#
# Seq2seq model with attention for transliteration
#

class EncoderRNN(nn.Module):
    """A bidirectional GRU encoder with an embedding layer.

    Outputs are projected from 2*hidden_dim back down to hidden_dim so the
    decoder's attention can match dimensions. The forward and backward final
    hidden states are combined into a single decoder-init hidden state.
    """
    def __init__(
        self, vocab_size, embedding_dim, hidden_dim,
        num_layers=1, dropout=0.1
    ):
        super().__init__()
        self.vocab_size = vocab_size
        self.embedding_dim = embedding_dim
        self.hidden_dim = hidden_dim
        self.num_layers = num_layers

        self.embedding = nn.Embedding(vocab_size, embedding_dim)
        self.gru = nn.GRU(
            embedding_dim, hidden_dim,
            num_layers=num_layers,
            batch_first=True,
            bidirectional=True,
            dropout=dropout if num_layers > 1 else 0.0,
        )
        self.out_proj = nn.Linear(2 * hidden_dim, hidden_dim)
        self.hidden_proj = nn.Linear(2 * hidden_dim, hidden_dim)
        self.dropout = nn.Dropout(dropout)

    def forward(self, input_seq):
        embedded = self.dropout(self.embedding(input_seq))
        # outputs: [B, S, 2H], hidden: [2*num_layers, B, H]
        outputs, hidden = self.gru(embedded)
        outputs = self.out_proj(outputs)  # [B, S, H]
        # Combine fwd/bwd final states for every layer so each decoder layer
        # gets a corresponding seed. hidden is laid out as
        # [layer0_fwd, layer0_bwd, layer1_fwd, layer1_bwd, ...].
        B, H = hidden.size(1), hidden.size(2)
        hidden = hidden.view(self.num_layers, 2, B, H)
        h_cat = torch.cat([hidden[:, 0], hidden[:, 1]], dim=-1)  # [L, B, 2H]
        dec_hidden = torch.tanh(self.hidden_proj(h_cat))  # [L, B, H]
        return outputs, dec_hidden


class BahdanauAttention(nn.Module):
    """Location-aware Bahdanau attention.

    Standard content-based scoring (Bahdanau 2014) augmented with features
    derived from the previous timestep's attention weights, as in Chorowski
    et al. 2015 (https://arxiv.org/abs/1506.07503). The location features
    bias attention to advance smoothly along the source — a useful inductive
    prior for monotonic tasks like transliteration, where alignment never
    reorders. Unlike strict monotonic attention, this is still soft: the
    model can revisit earlier positions if needed (e.g. for digraphs).

    Location features are produced by a 1D conv over the previous attention
    distribution, then projected into the score-energy space.
    """
    def __init__(self, hidden_size, loc_kernel_size=31, loc_features=32):
        super().__init__()
        self.Wa = nn.Linear(hidden_size, hidden_size)
        self.Ua = nn.Linear(hidden_size, hidden_size)
        self.Va = nn.Linear(hidden_size, 1)
        # Conv1d expects [B, C_in, S]; previous weights are [B, 1, S].
        # Padding keeps S unchanged.
        assert loc_kernel_size % 2 == 1, "kernel size must be odd"
        self.loc_conv = nn.Conv1d(
                1, loc_features,
                kernel_size=loc_kernel_size,
                padding=loc_kernel_size // 2,
                bias=False)
        self.loc_proj = nn.Linear(loc_features, hidden_size, bias=False)

    def forward(self, query, keys, mask=None, prev_attn=None):
        """
        Args:
            query: [B, 1, H]
            keys: [B, S, H]
            mask: [B, S] bool — True for valid (non-pad) positions
            prev_attn: [B, 1, S] — previous step's attention weights, or None
                on the first step (treated as a uniform prior over valid
                positions).

        Returns:
            context: [B, 1, H]
            weights: [B, 1, S]
        """
        B, S, H = keys.shape
        assert query.shape == (B, 1, H)

        if prev_attn is None:
            # Uniform prior over valid positions for the first step.
            if mask is not None:
                valid = mask.float()
                lengths = valid.sum(dim=-1, keepdim=True).clamp(min=1)
                prev_attn = (valid / lengths).unsqueeze(1)  # [B, 1, S]
            else:
                prev_attn = keys.new_full((B, 1, S), 1.0 / S)

        # Conv expects [B, 1, S]; outputs [B, F, S] -> [B, S, F]
        loc_feats = self.loc_conv(prev_attn).transpose(1, 2)
        loc_term = self.loc_proj(loc_feats)  # [B, S, H]

        scores = self.Va(torch.tanh(
                self.Wa(query) + self.Ua(keys) + loc_term))  # [B, S, 1]
        scores = scores.transpose(1, 2)  # [B, 1, S]
        if mask is not None:
            scores = scores.masked_fill(~mask.unsqueeze(1), float("-inf"))
        weights = F.softmax(scores, dim=-1)
        context = torch.bmm(weights, keys)
        return context, weights


class DecoderRNN(nn.Module):
    def __init__(
        self, vocab_size, embedding_dim, hidden_dim,
        num_layers=1, dropout=0.1, tie_weights=True,
    ):
        super().__init__()
        self.vocab_size = vocab_size
        self.embedding_dim = embedding_dim
        self.hidden_dim = hidden_dim
        self.num_layers = num_layers

        self.embedding = nn.Embedding(vocab_size, embedding_dim)
        self.dropout = nn.Dropout(dropout)
        self.attention = BahdanauAttention(hidden_dim)
        self.gru = nn.GRU(
            embedding_dim + hidden_dim, hidden_dim,
            num_layers=num_layers,
            batch_first=True,
            dropout=dropout if num_layers > 1 else 0.0,
        )
        self.out_proj = nn.Linear(hidden_dim, vocab_size)
        if tie_weights:
            # Share the input-embedding matrix with the output projection.
            # Saves vocab_size * hidden_dim parameters and tends to improve
            # generalization on small output vocabularies (common for
            # transliteration). Requires embedding_dim == hidden_dim.
            assert embedding_dim == hidden_dim, (
                "tie_weights requires embedding_dim == hidden_dim"
            )
            self.out_proj.weight = self.embedding.weight

    def forward(self, input_seq, hidden, enc_out, enc_mask=None,
                prev_attn=None):
        """Single token input, single token output.

        Returns (output, hidden, attn_weights). The attn_weights should be
        passed back as `prev_attn` on the next call to enable location-aware
        attention to track its own progress along the source sequence.
        """
        embedded = self.dropout(self.embedding(input_seq))
        # Use top layer's hidden state as the attention query.
        query = hidden[-1:].transpose(0, 1)  # [B, 1, H]
        context, attn_weights = self.attention(
                query, enc_out, enc_mask, prev_attn)
        # Luong-style dropout on the attention context: regularizes the
        # decoder's reliance on attention so the recurrent state carries
        # backup signal when attention is imperfect at inference.
        context = self.dropout(context)
        rnn_input = torch.cat([embedded, context], dim=-1)
        rnn_output, hidden = self.gru(rnn_input, hidden)
        output = self.out_proj(rnn_output)
        return output, hidden, attn_weights


class Seq2SeqRNN(nn.Module):
    def __init__(self, encoder, decoder, src_pad_id):
        super().__init__()
        self.encoder = encoder
        self.decoder = decoder
        self.src_pad_id = src_pad_id

    def forward(self, input_seq, target_seq):
        """Given the partial target sequence, predict the next token"""
        batch_size, target_len = target_seq.shape
        enc_mask = input_seq != self.src_pad_id  # [B, S]
        outputs = []
        enc_out, dec_hidden = self.encoder(input_seq)
        prev_attn = None
        for t in range(target_len - 1):
            # Teacher forcing: feed the ground-truth previous token.
            dec_in = target_seq[:, t].unsqueeze(1)
            dec_out, dec_hidden, prev_attn = self.decoder(
                    dec_in, dec_hidden, enc_out, enc_mask, prev_attn)
            outputs.append(dec_out)
        outputs = torch.cat(outputs, dim=1)
        return outputs


class S2S:
    def __init__(self, lang, state_fpath=None):
        """
        Instantiate a Seq2Seq model.

        @param lang (str) Language code. "per" and "ara" are supported.

        @param state_fpath (str) State file. Defaults to a predefined state
            file path based on the language selected. If the file is not found,
            the model must be retrained.
        """
        self.lang = lang

        # Data loaders.
        (self.train_loader, self.dev_loader,
         self.scr_tokenizer, self.rom_tokenizer) = get_dataloaders(self.lang)
        self.enc_dim = len(self.scr_tokenizer.get_vocab())
        self.dec_dim = len(self.rom_tokenizer.get_vocab())
        self.src_pad_id = self.scr_tokenizer.token_to_id(PAD_TOK)
        self.tgt_pad_id = self.rom_tokenizer.token_to_id(PAD_TOK)
        self.params = PARAMS[lang]

        # Encoder & decoder.
        # Hidden dimensions must be the same of embedded dimensions.
        encoder = EncoderRNN(
            self.enc_dim, self.params["emb_dim"],
            self.params['emb_dim'], self.params["n_layers"],
            self.params["dropout"]
        ).to(DEVICE)
        decoder = DecoderRNN(
            self.dec_dim, self.params["emb_dim"],
            self.params['emb_dim'], self.params["n_layers"],
            self.params["dropout"]
        ).to(DEVICE)

        # Seq2SeqRNN model.
        self.model = Seq2SeqRNN(encoder, decoder, self.src_pad_id).to(DEVICE)
        state_dir = path.join(DATA_ROOT, "train_state", self.lang)
        self.state_fpath = path.join(state_dir, "checkpoint.pth")
        self.best_fpath = path.join(state_dir, "best.pth")
        # Prefer the best-on-dev checkpoint when both exist.
        load_path = (
            state_fpath if state_fpath and path.exists(self.state_fpath)
            else self.best_fpath if path.exists(self.best_fpath)
            else self.state_fpath if path.exists(self.state_fpath)
            else None
        )
        if load_path is not None:
            logger.debug(f"Loading checkpoint: {load_path}")
            self.model.load_state_dict(torch.load(
                    load_path,  map_location=DEVICE))
            self.trained = True
        else:
            logger.warn("Model is not trained.")
            self.trained = False

        total_params = sum(
                p.numel() for p in self.model.parameters() if p.requires_grad)
        logger.debug(f"Seq2Seq model created for language: {lang}")
        logger.debug("Parameters:")
        logger.debug(f"  Input vocabulary size: {self.enc_dim}")
        logger.debug(f"  Output vocabulary size: {self.dec_dim}")
        logger.debug(f"  Embedding dimension: {PARAMS[lang]['emb_dim']}")
        logger.debug(f"  Hidden dimension: {PARAMS[lang]['emb_dim']}")
        logger.debug(f"  Dropout: {PARAMS[lang]['dropout']}")
        logger.debug(f"  Total parameters: {total_params}")

    def train(self, epochs=0, eval_every=5, patience=5):
        """Train with LR-on-plateau and best-checkpoint-on-dev-loss.

        eval_every: run dev evaluation every N epochs.
        patience: stop after this many consecutive eval cycles without
            improvement on dev loss. Ignored if no dev set is configured.
        """
        if epochs == 0:
            epochs = self.params["n_epochs"]
        logger.info(f"Training for up to {epochs} epochs.")
        if self.trained:
            logger.debug("Backing up existing state file.")
            copy(self.state_fpath, self.state_fpath + ".bk")
        else:
            makedirs(path.dirname(self.state_fpath), exist_ok=True)

        optimizer = optim.AdamW(
                self.model.parameters(), lr=self.params["lr"],
                weight_decay=self.params["weight_decay"])
        loss_fn = nn.CrossEntropyLoss(ignore_index=self.tgt_pad_id)
        # Linear warmup for the first epoch, then plateau decay on dev loss.
        warmup_steps = max(self.params["warmup"], len(self.train_loader))
        warmup = optim.lr_scheduler.LinearLR(
                optimizer, start_factor=0.1, end_factor=1.0,
                total_iters=warmup_steps)
        scheduler = optim.lr_scheduler.ReduceLROnPlateau(
                optimizer, mode="min", factor=0.5, patience=1)

        best_dev_loss = float("inf")
        stale_evals = 0

        for epoch in range(epochs):
            self.model.train()
            epoch_loss = 0
            for scr_ids, rom_ids in tqdm.tqdm(
                    self.train_loader, desc="Training"):
                scr_ids = scr_ids.to(DEVICE)
                rom_ids = rom_ids.to(DEVICE)
                optimizer.zero_grad()
                outputs = self.model(scr_ids, rom_ids)
                loss = loss_fn(outputs.reshape(
                        -1, self.dec_dim), rom_ids[:, 1:].reshape(-1))
                loss.backward()
                torch.nn.utils.clip_grad_norm_(
                        self.model.parameters(), self.params["grad_clip"])
                optimizer.step()
                if warmup.last_epoch < warmup.total_iters:
                    warmup.step()
                epoch_loss += loss.item()
            logger.info(
                f"Epoch {epoch+1}/{epochs}; "
                f"Avg loss {epoch_loss/len(self.train_loader)}; "
                f"Latest loss {loss.item()}"
            )
            # Latest snapshot — overwritten every epoch.
            torch.save(self.model.state_dict(), self.state_fpath)

            if (epoch + 1) % eval_every != 0 or self.dev_loader is None:
                continue
            self.model.eval()
            eval_loss = 0
            with torch.no_grad():
                for scr_ids, rom_ids in tqdm.tqdm(
                        self.dev_loader, desc="Evaluating"):
                    scr_ids = scr_ids.to(DEVICE)
                    rom_ids = rom_ids.to(DEVICE)
                    outputs = self.model(scr_ids, rom_ids)
                    loss = loss_fn(outputs.reshape(
                            -1, self.dec_dim), rom_ids[:, 1:].reshape(-1))
                    eval_loss += loss.item()
            avg_dev = eval_loss / len(self.dev_loader)
            current_lr = optimizer.param_groups[0]["lr"]
            logger.info(
                    f"Eval loss (dev): {avg_dev:.4f}; lr: {current_lr:.2e}")

            scheduler.step(avg_dev)

            if avg_dev < best_dev_loss:
                best_dev_loss = avg_dev
                torch.save(self.model.state_dict(), self.best_fpath)
                logger.info(f"New best dev loss → saved {self.best_fpath}")
                stale_evals = 0
            else:
                stale_evals += 1
                logger.info(f"No dev improvement ({stale_evals}/{patience}).")
                if stale_evals >= patience:
                    logger.info(f"Early stopping at epoch {epoch+1}.")
                    break

        torch.save(self.model.state_dict(), self.state_fpath)
        # Reload best weights so the live model reflects the best checkpoint.
        if path.exists(self.best_fpath):
            self.model.load_state_dict(torch.load(self.best_fpath))
            logger.info(
                f"Reloaded best dev checkpoint (loss {best_dev_loss:.4f})."
            )
        self.trained = True

    def _greedy_decode(self, src, max_len):
        scr_ids = torch.tensor(
            self.scr_tokenizer.encode(src).ids
        ).unsqueeze(0).to(DEVICE)
        enc_mask = scr_ids != self.src_pad_id
        enc_out, hidden = self.model.encoder(scr_ids)
        prev_token = torch.tensor(
            [[self.rom_tokenizer.token_to_id(SOS_TOK)]]
        ).to(DEVICE)
        eos_id = self.rom_tokenizer.token_to_id(EOS_TOK)
        pred_ids = []
        prev_attn = None
        for _ in range(max_len):
            output, hidden, prev_attn = self.model.decoder(
                    prev_token, hidden, enc_out, enc_mask, prev_attn)
            output = output.argmax(dim=2)
            pred_ids.append(output.item())
            prev_token = output
            if pred_ids[-1] == eos_id:
                break
        return pred_ids

    def _beam_decode(self, src, max_len, beam_size=4, length_penalty=0.6):
        """Beam search with Wu et al. length normalization.

        Returns the token-id list of the highest-scoring completed hypothesis,
        or the best live beam if none completed within max_len.
        """
        sos_id = self.rom_tokenizer.token_to_id(SOS_TOK)
        eos_id = self.rom_tokenizer.token_to_id(EOS_TOK)

        scr_ids = torch.tensor(
            self.scr_tokenizer.encode(src).ids
        ).unsqueeze(0).to(DEVICE)
        enc_mask = scr_ids != self.src_pad_id
        enc_out, hidden = self.model.encoder(scr_ids)

        # Tile encoder state across the beam dimension.
        # enc_out: [B=1, S, H] -> [K, S, H]; hidden: [L, B=1, H] -> [L, K, H]
        enc_out = enc_out.expand(beam_size, -1, -1).contiguous()
        enc_mask = enc_mask.expand(beam_size, -1).contiguous()
        hidden = hidden.expand(-1, beam_size, -1).contiguous()

        # Per-beam state.
        seqs = torch.full(
                (beam_size, 1), sos_id, dtype=torch.long, device=DEVICE)
        scores = torch.zeros(beam_size, device=DEVICE)
        # Mark all but the first beam as -inf so step 1 only expands beam 0
        # (otherwise all beams start identical and produce K duplicate top-K).
        scores[1:] = float("-inf")

        finished = []  # list of (normalized_score, token_ids)
        prev_attn = None  # threaded through location-aware attention

        def lp(length):
            return ((5 + length) / 6) ** length_penalty

        for step in range(max_len):
            prev_token = seqs[:, -1:]  # [K, 1]
            output, hidden, prev_attn = self.model.decoder(
                    prev_token, hidden, enc_out, enc_mask, prev_attn)
            log_probs = F.log_softmax(output.squeeze(1), dim=-1)  # [K, V]
            V = log_probs.size(-1)

            # Total scores for all K*V continuations.
            total = scores.unsqueeze(1) + log_probs  # [K, V]
            flat = total.view(-1)
            top_scores, top_idx = flat.topk(beam_size)
            beam_idx = top_idx // V  # which parent beam
            tok_idx = top_idx % V    # which token

            new_seqs = torch.cat(
                    [seqs[beam_idx], tok_idx.unsqueeze(1)], dim=1)
            # Reorder hidden state and prev_attn to match the chosen parents.
            hidden = hidden[:, beam_idx, :].contiguous()
            prev_attn = prev_attn[beam_idx].contiguous()
            scores = top_scores

            # Move EOS-terminated beams to finished and replace with -inf so
            # they no longer compete for top-K next round.
            still_alive = []
            for i in range(beam_size):
                if tok_idx[i].item() == eos_id:
                    seq = new_seqs[i].tolist()
                    norm = scores[i].item() / lp(len(seq) - 1)  # exclude SOS
                    finished.append((norm, seq))
                    scores[i] = float("-inf")
                else:
                    still_alive.append(i)

            seqs = new_seqs
            if len(finished) >= beam_size or not still_alive:
                break

        if finished:
            finished.sort(key=lambda x: x[0], reverse=True)
            best = finished[0][1]
        else:
            # No EOS within max_len — pick best live beam, length-normalized.
            best_i = max(
                    range(beam_size),
                    key=lambda i: scores[i].item() / lp(seqs.size(1) - 1))
            best = seqs[best_i].tolist()

        # Strip leading SOS; trailing EOS (if present) is fine for the decoder.
        return best[1:]

    def transliterate(self, src, beam_size=4):
        # Apply training-time normalization so the tokenizer sees the same
        # form it was trained on (e.g. Arabic yeh → Persian yeh).
        src = normalize_fn[self.lang](src)
        self.model.eval()
        with torch.no_grad():
            if beam_size <= 1:
                pred_ids = self._greedy_decode(src, max_len=MAX_SRC_CHARS)
            else:
                pred_ids = self._beam_decode(
                        src, max_len=MAX_SRC_CHARS, beam_size=beam_size)
        eos_id = self.rom_tokenizer.token_to_id(EOS_TOK)
        if pred_ids and pred_ids[-1] == eos_id:
            pred_ids = pred_ids[:-1]
        return self.rom_tokenizer.decode(pred_ids)

    def sample_predictions(self, ct=5, beam_size=4, split="dev"):
        """Print a handful of full predictions for visual inspection."""
        self.model.eval()
        pairs = read_langs(self.lang, split)
        eos_id = self.rom_tokenizer.token_to_id(EOS_TOK)
        with torch.no_grad():
            for scr, true_rom in random.sample(pairs, ct):
                if beam_size <= 1:
                    pred_ids = self._greedy_decode(scr, max_len=60)
                else:
                    pred_ids = self._beam_decode(
                            scr, max_len=60, beam_size=beam_size)
                if pred_ids and pred_ids[-1] == eos_id:
                    pred_ids = pred_ids[:-1]
                pred_rom = self.rom_tokenizer.decode(pred_ids)
                print(f"Script:     {scr}")
                print(f"Roman:      {true_rom}")
                print(f"Predicted:  {pred_rom}")

    def evaluate(self, split="test", beam_size=4, max_len=60, limit=None):
        """End-to-end transliteration metrics on a held-out split.

        Runs full inference (beam or greedy) over every pair in the split
        and reports:
          - exact match: predicted == reference (after stripping trailing EOS)
          - CER: character error rate (Levenshtein / |reference|)
          - WER: word error rate (token-level Levenshtein / |reference words|)

        Args:
            split: which CSV under data/source/<lang>/ to evaluate.
            beam_size: 1 for greedy, >1 for beam search.
            max_len: decoder step cap.
            limit: optional cap on number of pairs to evaluate (for spot
                checks during training).
        """
        self.model.eval()
        pairs = read_langs(self.lang, split)
        if limit is not None:
            pairs = pairs[:limit]

        eos_id = self.rom_tokenizer.token_to_id(EOS_TOK)
        n = len(pairs)
        exact = 0
        char_edits = 0
        char_total = 0
        word_edits = 0
        word_total = 0

        with torch.no_grad():
            for scr, true_rom in tqdm.tqdm(pairs, desc=f"Evaluating {split}"):
                if beam_size <= 1:
                    pred_ids = self._greedy_decode(scr, max_len=max_len)
                else:
                    pred_ids = self._beam_decode(
                            scr, max_len=max_len, beam_size=beam_size)
                # Strip a trailing EOS if present so it doesn't pollute CER.
                if pred_ids and pred_ids[-1] == eos_id:
                    pred_ids = pred_ids[:-1]
                pred = self.rom_tokenizer.decode(pred_ids).strip()
                ref = true_rom.strip()

                if pred == ref:
                    exact += 1
                char_edits += _levenshtein(pred, ref)
                char_total += max(len(ref), 1)
                pred_words = pred.split()
                ref_words = ref.split()
                word_edits += _levenshtein(pred_words, ref_words)
                word_total += max(len(ref_words), 1)

        em = exact / n if n else 0.0
        cer = char_edits / char_total if char_total else 0.0
        wer = word_edits / word_total if word_total else 0.0
        print(
            f"\n[{split}] n={n}  exact={em:.4f}  CER={cer:.4f}  WER={wer:.4f}"
            f"  beam={beam_size}"
        )
        return {"n": n, "exact_match": em, "cer": cer, "wer": wer}
