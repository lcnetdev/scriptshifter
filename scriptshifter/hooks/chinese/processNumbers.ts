private processNumbers(pinyinString: string, tag: string, code: string): string {
    let outputString = "";
    let useNumVersion = false;
    //useNumVersion is set in specific subfields where we definitely want to treat numbers as numbers
    if ((tag == "245" || tag == "830") && code == "n") {
       useNumVersion = true;
    }

    /*
     * The input string is split, with any space or punctuation character (except for #) as the delimiter.
     * The delimiters will be captured and included in the string of tokens.  Only the even-numbered
     * array elements are the true 'tokens', so the code for processing tokens is run only for even
     * values of j.
     */
    let tokens: string[] = pinyinString.split(new RegExp("([^\\P{P}#]|\\s)","u"));
    let numTokenPattern = "^([A-Za-z]+)#([0-9]*)$";
    let numToken_re = new RegExp(numTokenPattern);
    let n = tokens.length
    //this.alert.info(tokens.join("|"),{autoClose: false})
    for (let i = 0; i < n; i++) {
        let toki = tokens[i];
        if (toki.match(numToken_re)) {
            /*
             * When a numerical token (containing #) is reached, the inner loop consumes it and all consecutive numerical tokens
             * found after it.  Two versions of the string are maintained.  The textVersion is the original pinyin (minus the
             * # suffixes).  In the numVersion, characters representing numbers are converted to Arabic numerals.  When a
             * non-numerical token (or end of string) is encountered, the string of numerical tokens is evaluated to determine
             * which version should be used in the output string.  The outer loop then continues where the inner loop left off.
             */
            let textVersion = "";
            let numVersion = "";
            for (let j = i; j < n; j++) {
                let tokj = tokens[j];
                /* a token without # (or the end of string) is reached */
                if ((j % 2 == 0 && !tokj.match(numToken_re)) || j == n - 1) {
                    //If this runs, then we are on the last token and it is numeric. Add text after # (if present) to numerical version
                    let m = tokj.match(numToken_re);
                    if (m) {
                        textVersion += m[1]
                        if (m[2] == "") {
                            numVersion += m[1];
                        } else {
                            numVersion += m[2];
                        }
                    } else if (j == n - 1) {
                    //if last token is non-numerical, just tack it on.
                        textVersion += tokj;
                        numVersion += tokj;
                    } else if (textVersion.length > 0 && numVersion.length > 0) {
                    //if not at end of string yet and token is non-numerical, remove the last delimiter that was appended
                    //(outer loop will pick up at this point)
                        textVersion = textVersion.substring(0, textVersion.length - 1);
                        numVersion = numVersion.substring(0, numVersion.length - 1);
                    }
                    //evaluate numerical string that has been constructed so far
                    //use num version for ordinals and date strings
                    if (numVersion.match(/^di [0-9]/i) ||
                        numVersion.match(/[0-9] [0-9] [0-9] [0-9]/) ||
                        numVersion.match(/[0-9]+ nian [0-9]+ yue/i) ||
                        numVersion.match(/"[0-9]+ yue [0-9]+ ri/i) ||
                        useNumVersion
                       ) {
                        useNumVersion = true;
                        /*
                         * At this point, string may contain literal translations of Chinese numerals
                         * Convert these to Arabic numerals (for example "2 10 7" = "27").
                         */

                        while (numVersion.match(/[0-9] 10+/) || numVersion.match(/[1-9]0+ [1-9]/)) {
                            m = numVersion.match(/([0-9]+) ([1-9]0+)/);
                            if (m) {
                                let sum = Number(m[1]) * Number(m[2]);
                                numVersion = numVersion.replace(/[0-9]+ [1-9]0+/, String(sum));
                            } else {
                                let mb = numVersion.match(/([1-9]0+) ([0-9]+)/);
                                if (mb)
                                {
                                    let sumb = Number(mb[1]) + Number(mb[2]);
                                    numVersion = numVersion.replace(/[1-9]0+ [0-9]+/, String(sumb));
                                }
                                else
                                {
                                    break;
                                }
                            }
                        }

                        //A few other tweaks
                        numVersion = numVersion.replace(/([0-9]) ([0-9]) ([0-9]) ([0-9])/g, "$1$2$3$4");
                        if ((tag == "245" || tag == "830") && code == "n") {
                            while (numVersion.match(/[0-9] [0-9]/)) {
                                numVersion = numVersion.replace(/([0-9]) ([0-9])/, "$1$2");
                            }
                        }
                    }
                    if (useNumVersion)
                    {
                        outputString += numVersion;
                    }
                    else
                    {
                        outputString += textVersion;
                    }
                    //if the end of the string is not reached, backtrack to the delimiter after the last numerical token
                    //(i.e. two tokens ago)
                    if (j < n - 1)
                    {
                        i = j - 2;
                    }
                    else //we are at the end of the string, so we are done!
                    {
                        i = j;
                    }
                    break;
                }
                //this is run when we are not yet at the end of the string and have not yet reached a non-numerical token
                //This is identical to the code that is run above when the last token is numeric.
                if (j % 2 == 0)
                {
                    let m = tokj.match(numToken_re);
                    textVersion += m[1];
                    if (m[2]== "")
                    {
                        numVersion += m[1];
                    }
                    else
                    {
                        numVersion += m[2];
                    }
                }
                else //a delimiter, just tack it on.
                {
                    textVersion += tokj;
                    numVersion += tokj;
                }
            }
        }
        else // the outer loop has encountered a non-numeric token or delimiter, just tack it on.
        {
            outputString += toki;
        }
    }
    return outputString;
 }
