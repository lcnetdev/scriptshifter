document.getElementById('lang').addEventListener('change',(event)=>{
    let lang = document.getElementById("lang").value;

    fetch('/options/' + lang)
      .then(response=>response.json())
        .then((data) => {
            document.getElementById("options").replaceChildren();
            data.forEach((opt)=>{
                let fset = document.createElement("fieldset");
                let label = document.createElement("label");
                label.setAttribute("for", opt.id);
                label.append(opt.label);

                let input = document.createElement("input");
                input.setAttribute("id", opt.id);
                input.setAttribute("name", opt.id);
                input.classList.add("option_i");
                input.value = opt.default;

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
document.getElementById('lang').dispatchEvent(new Event('change'));


document.getElementById('transliterate').addEventListener('submit',(event)=>{

    document.getElementById('feedback_cont').classList.add("hidden");
    document.getElementById('loader_results').classList.remove("hidden");

    const data = new URLSearchParams();

    let t_dir = Array.from(document.getElementsByName("t_dir")).find(r => r.checked).value;

    let capitalize = Array.from(document.getElementsByName("capitalize")).find(r => r.checked).value;


    data.append('text',document.getElementById('text').value)
    data.append('lang',document.getElementById('lang').value)
    data.append('t_dir',t_dir)
    data.append('capitalize',capitalize)

    let options = {};
    let option_inputs = document.getElementsByClassName("option_i");
    for (i = 0; i < option_inputs.length; i++) {
        let el = option_inputs[i];
        options[el.getAttribute('id')] = el.value;
    };
    data.append('options', JSON.stringify(options));

    fetch('/trans', {
        method: 'post',
        body: data,
    })
    .then(response=>response.json())
    .then((results)=>{

        document.getElementById('warnings-toggle').classList.add("hidden");
        document.getElementById('loader_results').classList.add("hidden");

        document.getElementById('results').innerText = results.output
        document.getElementById('feedback_btn_cont').classList.remove("hidden");

        if (results.warnings.length>0){
            document.getElementById('warnings-toggle').classList.remove("hidden");
            document.getElementById('warnings').innerText = "WARNING:\n" + results.warnings.join("\n")
        }


    }).catch((error) => {
      alert("Error:\n" + error)
    });

    event.preventDefault()
    return false

})

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
    const data = new URLSearchParams();
    data.append('lang', document.getElementById('lang_fb_input').value);
    data.append('src', document.getElementById('src_fb_input').value);
    data.append('t_dir', document.getElementById('t_dir_fb_input').value);
    data.append('result', document.getElementById('result_fb_input').value);
    data.append('expected', document.getElementById('expected_fb_input').value);
    data.append('contact', document.getElementById('contact_fb_input').value);
    data.append('notes', document.getElementById('notes_fb_input').value);

    let options = {};
    let option_inputs = document.getElementsByClassName("option_i");
    for (i = 0; i < option_inputs.length; i++) {
        let el = option_inputs[i];
        options[el.getAttribute('id')] = el.value;
    };
    data.append('options', JSON.stringify(options));

    fetch('/feedback', {
        method: 'post',
        body: data,
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