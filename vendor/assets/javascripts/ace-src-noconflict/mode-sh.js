/* ***** BEGIN LICENSE BLOCK *****
 * Distributed under the BSD license:
 *
 * Copyright (c) 2010, Ajax.org B.V.
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of Ajax.org B.V. nor the
 *       names of its contributors may be used to endorse or promote products
 *       derived from this software without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL AJAX.ORG B.V. BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * ***** END LICENSE BLOCK ***** */

ace.define('ace/mode/sh', ['require', 'exports', 'module' , 'ace/lib/oop', 'ace/mode/text', 'ace/tokenizer', 'ace/mode/sh_highlight_rules', 'ace/range'], function(require, exports, module) {


var oop = require("../lib/oop");
var TextMode = require("./text").Mode;
var Tokenizer = require("../tokenizer").Tokenizer;
var ShHighlightRules = require("./sh_highlight_rules").ShHighlightRules;
var Range = require("../range").Range;

var Mode = function() {
    this.HighlightRules = ShHighlightRules;
};
oop.inherits(Mode, TextMode);

(function() {

   
    this.lineCommentStart = "#";

    this.getNextLineIndent = function(state, line, tab) {
        var indent = this.$getIndent(line);

        var tokenizedLine = this.getTokenizer().getLineTokens(line, state);
        var tokens = tokenizedLine.tokens;

        if (tokens.length && tokens[tokens.length-1].type == "comment") {
            return indent;
        }

        if (state == "start") {
            var match = line.match(/^.*[\{\(\[\:]\s*$/);
            if (match) {
                indent += tab;
            }
        }

        return indent;
    };

    var outdents = {
        "pass": 1,
        "return": 1,
        "raise": 1,
        "break": 1,
        "continue": 1
    };

    this.checkOutdent = function(state, line, input) {
        if (input !== "\r\n" && input !== "\r" && input !== "\n")
            return false;

        var tokens = this.getTokenizer().getLineTokens(line.trim(), state).tokens;

        if (!tokens)
            return false;
        do {
            var last = tokens.pop();
        } while (last && (last.type == "comment" || (last.type == "text" && last.value.match(/^\s+$/))));

        if (!last)
            return false;

        return (last.type == "keyword" && outdents[last.value]);
    };

    this.autoOutdent = function(state, doc, row) {

        row += 1;
        var indent = this.$getIndent(doc.getLine(row));
        var tab = doc.getTabString();
        if (indent.slice(-tab.length) == tab)
            doc.remove(new Range(row, indent.length-tab.length, row, indent.length));
    };

}).call(Mode.prototype);

exports.Mode = Mode;
});

ace.define('ace/mode/sh_highlight_rules', ['require', 'exports', 'module' , 'ace/lib/oop', 'ace/mode/text_highlight_rules'], function(require, exports, module) {


var oop = require("../lib/oop");
var TextHighlightRules = require("./text_highlight_rules").TextHighlightRules;

var reservedKeywords = exports.reservedKeywords = (
        '!|{|}|case|do|done|elif|else|'+
        'esac|fi|for|if|in|then|until|while|'+
        '&|;|export|local|read|typeset|unset|'+
        'elif|select|set'
    );

var languageConstructs = exports.languageConstructs = (
    '[|]|alias|bg|bind|break|builtin|'+
     'cd|command|compgen|complete|continue|'+
     'dirs|disown|echo|enable|eval|exec|'+
     'exit|fc|fg|getopts|hash|help|history|'+
     'jobs|kill|let|logout|popd|printf|pushd|'+
     'pwd|return|set|shift|shopt|source|'+
     'suspend|test|times|trap|type|ulimit|'+
     'umask|unalias|wait'
);

var ShHighlightRules = function() {
    var keywordMapper = this.createKeywordMapper({
        "keyword": reservedKeywords,
        "support.function.builtin": languageConstructs,
        "invalid.deprecated": "debugger"
    }, "identifier");

    var integer = "(?:(?:[1-9]\\d*)|(?:0))";

    var fraction = "(?:\\.\\d+)";
    var intPart = "(?:\\d+)";
    var pointFloat = "(?:(?:" + intPart + "?" + fraction + ")|(?:" + intPart + "\\.))";
    var exponentFloat = "(?:(?:" + pointFloat + "|" +  intPart + ")" + ")";
    var floatNumber = "(?:" + exponentFloat + "|" + pointFloat + ")";
    var fileDescriptor = "(?:&" + intPart + ")";

    var variableName = "[a-zA-Z][a-zA-Z0-9_]*";
    var variable = "(?:(?:\\$" + variableName + ")|(?:" + variableName + "=))";

    var builtinVariable = "(?:\\$(?:SHLVL|\\$|\\!|\\?))";

    var func = "(?:" + variableName + "\\s*\\(\\))";

    this.$rules = {
        "start" : [{
            token : "constant",
            regex : /\\./
        }, {
            token : ["text", "comment"],
            regex : /(^|\s)(#.*)$/
        }, {
            token : "string",
            regex : '"',
            push : [{
                token : "constant.language.escape",
                regex : /\\(?:[$abeEfnrtv\\'"]|x[a-fA-F\d]{1,2}|u[a-fA-F\d]{4}([a-fA-F\d]{4})?|c.|\d{1,3})/
            }, {
                token : "constant",
                regex : /\$\w+/
            }, {
                token : "string",
                regex : '"',
                next: "pop"
            }, {
                defaultToken: "string"
            }]
        }, {
            token : "variable.language",
            regex : builtinVariable
        }, {
            token : "variable",
            regex : variable
        }, {
            token : "support.function",
            regex : func
        }, {
            token : "support.function",
            regex : fileDescriptor
        }, {
            token : "string",           // ' string
            start : "'", end : "'"
        }, {
            token : "constant.numeric", // float
            regex : floatNumber
        }, {
            token : "constant.numeric", // integer
            regex : integer + "\\b"
        }, {
            token : keywordMapper,
            regex : "[a-zA-Z_$][a-zA-Z0-9_$]*\\b"
        }, {
            token : "keyword.operator",
            regex : "\\+|\\-|\\*|\\*\\*|\\/|\\/\\/|~|<|>|<=|=>|=|!="
        }, {
            token : "paren.lparen",
            regex : "[\\[\\(\\{]"
        }, {
            token : "paren.rparen",
            regex : "[\\]\\)\\}]"
        } ]
    };
    
    this.normalizeRules();
};

oop.inherits(ShHighlightRules, TextHighlightRules);

exports.ShHighlightRules = ShHighlightRules;
});
