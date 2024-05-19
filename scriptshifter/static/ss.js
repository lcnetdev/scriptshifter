var fb_btn = document.getElementById('feedback_btn_cont');
var fb_active = fb_btn != undefined;

// URL parameters
var qd = {};
if (location.search) location.search.substr(1).split("&").forEach(function(item) {
    var s = item.split("="),
        k = s[0],
        v = s[1] && decodeURIComponent(s[1]);
    (qd[k] = qd[k] || []).push(v)
})


document.getElementById('lang').addEventListener('change',(event)=>{
    let lang = document.getElementById("lang").value;

    fetch('/options/' + lang)
      .then(response=>response.json())
        .then((data) => {
            document.getElementById("options").replaceChildren();
            if (data.length > 0) {
                let hdr = document.createElement("h3");
                hdr.innerText = "Language options";
                document.getElementById("options").append(hdr);
            }
            data.forEach((opt)=>{
                let fset = document.createElement("fieldset");
                fset.setAttribute("class", "float-left");
                let label = document.createElement("label");
                label.setAttribute("for", opt.id);
                label.append(opt.label);

                var input;
                if (opt.type == "list") {
                    input = document.createElement("select");
                    opt.options.forEach((sel) => {
                        let option = document.createElement("option");
                        option.append(sel.label);
                        option.value = sel.id;
                        if (option.value == opt.default) {
                            option.selected = true;
                        };
                        input.append(option);
                    })
                } else if (opt.type == "boolean") {
                    // Use checkbox for boolean type.
                    input = document.createElement("input");
                    input.setAttribute("type", "checkbox");
                    if (opt.default) {
                        input.setAttribute("checked", 1);
                    }
                } else {
                    // Use text for all other types.
                    input = document.createElement("input");
                    input.value = opt.default;
                }
                input.setAttribute("id", opt.id);
                input.setAttribute("name", opt.id);
                input.classList.add("option_i");

                let descr = document.createElement("p");
                descr.setAttribute("class", "input_descr");
                descr.append(opt.description);

                fset.append(label, descr, input);
                document.getElementById("options").append(fset);
            });
        });

    event.preventDefault();
    return false;
})

// Change language select menu based on query string
var nav_lang = qd["lang"]
if (nav_lang != undefined) {
    var lang_sel = document.getElementById("lang");
    Array.from(lang_sel.options).every(item => {
        if (item.value == nav_lang) {
            lang_sel.value = nav_lang;
            return false;
        }
        return true;
    })
}
// Trigger the change event to process lang options.
document.getElementById('lang').dispatchEvent(new Event('change'));


document.getElementById('transliterate').addEventListener('submit',(event)=>{

    if (fb_active) {
        document.getElementById('feedback_cont').classList.add("hidden");
    }
    document.getElementById('loader_results').classList.remove("hidden");

    let t_dir = Array.from(document.getElementsByName("t_dir")).find(r => r.checked).value;

    let capitalize = Array.from(document.getElementsByName("capitalize")).find(r => r.checked).value;


    const data = {
        'text': document.getElementById('text').value,
        'lang': document.getElementById('lang').value,
        't_dir': t_dir,
        'capitalize': capitalize,
        'options': {}
    }

    let option_inputs = document.getElementsByClassName("option_i");
    for (i = 0; i < option_inputs.length; i++) {
        let el = option_inputs[i];
        if (el.type == "checkbox") {
            data['options'][el.id] = el.checked;
        } else {
            data['options'][el.id] = el.value;
        }
    };

    fetch('/trans', {
        method: 'post',
        body: JSON.stringify(data),
        headers: {"Content-Type": "application/json"}
    })
    .then(response=>response.json())
    .then((results)=>{

        document.getElementById('warnings-toggle').classList.add("hidden");
        document.getElementById('loader_results').classList.add("hidden");

        document.getElementById('results').innerText = results.output
        if (fb_active) {
            fb_btn.classList.remove("hidden");
        }

        if (results.warnings && results.warnings.length>0){
            document.getElementById('warnings-toggle').classList.remove("hidden");
            document.getElementById('warnings').innerText = "WARNING:\n" + results.warnings.join("\n")
        }


    }).catch((error) => {
      alert("Error:\n" + error)
    });

    event.preventDefault()
    return false

})

if (fb_active) {
    document.getElementById('feedback_btn').addEventListener('click',(event)=>{
        document.getElementById('lang_fb_input').value = document.getElementById('lang').value;
        document.getElementById('src_fb_input').value = document.getElementById('text').value;
        document.getElementById('t_dir_fb_input').value = Array.from(
            document.getElementsByName("t_dir")
        ).find(r => r.checked).value;
        document.getElementById('result_fb_input').value = document.getElementById('results').innerText;
        document.getElementById('expected_fb_input').value = "";
        document.getElementById('notes_fb_input').value = "";
        document.getElementById('options_fb_input').value = ""; // TODO

        document.getElementById('feedback_cont').classList.remove("hidden");

        location.href = "#";
        location.href = "#feedback_cont";
    })

    document.getElementById('feedback_form').addEventListener('submit',(event)=>{
        const data = {
            'lang': document.getElementById('lang_fb_input').value,
            'src': document.getElementById('src_fb_input').value,
            't_dir': document.getElementById('t_dir_fb_input').value,
            'result': document.getElementById('result_fb_input').value,
            'expected': document.getElementById('expected_fb_input').value,
            'contact': document.getElementById('contact_fb_input').value,
            'notes': document.getElementById('notes_fb_input').value,
            'options': {}
        };

        let option_inputs = document.getElementsByClassName("option_i");
        for (i = 0; i < option_inputs.length; i++) {
            let el = option_inputs[i];
            data['options'][el.getAttribute('id')] = el.value;
        };

        fetch('/feedback', {
            method: 'post',
            body: JSON.stringify(data),
            headers: {"Content-Type": "application/json"}
        })
        .then(response=>response.json())
        .then((results)=>{
            alert(
                "Thanks for your feedback. You should receive an email with "
                + "a copy of your submission."
            );

            document.getElementById('feedback_cont').classList.add("hidden");
            document.getElementById('feedback_form').reset();
            location.href = "#";

        })

        event.preventDefault();
        return false;
    })

    document.getElementById('cancel_fb_btn').addEventListener('click',(event)=>{
        document.getElementById('feedback_cont').classList.add("hidden");
        document.getElementById('feedback_form').reset();
        location.href = "#";

        event.preventDefault();
        return false;
    })
}

