from esupar import load


def s2r_tokenize(ctx, model):
    nlp = load(model)
    token_data = nlp(ctx.src)

    ctx._src = " ".join(token_data.values[1])
