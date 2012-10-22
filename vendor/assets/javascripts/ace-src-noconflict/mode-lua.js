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

ace.define('ace/mode/lua', ['require', 'exports', 'module' , 'ace/lib/oop', 'ace/mode/text', 'ace/tokenizer', 'ace/mode/lua_highlight_rules', 'ace/range'], function(require, exports, module) {


var oop = require("../lib/oop");
var TextMode = require("./text").Mode;
var Tokenizer = require("../tokenizer").Tokenizer;
var LuaHighlightRules = require("./lua_highlight_rules").LuaHighlightRules;
var Range = require("../range").Range;

var Mode = function() {
    this.$tokenizer = new Tokenizer(new LuaHighlightRules().getRules());
};
oop.inherits(Mode, TextMode);

(function() {
    var indentKeywords = {
        "function": 1,
        "then": 1,
        "do": 1,
        "else": 1,
        "elseif": 1,
        "repeat": 1,
        "end": -1,
        "until": -1,
    };
    var outdentKeywords = [
        "else",
        "elseif",
        "end",
        "until"
    ];

    function getNetIndentLevel(tokens) {
        var level = 0;
        // Support single-line blocks by decrementing the indent level if
        // an ending token is found
        for (var i in tokens){
            var token = tokens[i];
            if (token.type == "keyword") {
                if (token.value in indentKeywords) {
                    level += indentKeywords[token.value];
                }
            } else if (token.type == "paren.lparen") {
                level ++;
            } else if (token.type == "paren.rparen") {
                level --;
            }
        }
        // Limit the level to +/- 1 since usually users only indent one level
        // at a time regardless of the logical nesting level
        if (level < 0) {
            return -1;
        } else if (level > 0) {
            return 1;
        } else {
            return 0;
        }
    }

    this.getNextLineIndent = function(state, line, tab) {
        var indent = this.$getIndent(line);
        var level = 0;

        var tokenizedLine = this.$tokenizer.getLineTokens(line, state);
        var tokens = tokenizedLine.tokens;

        if (state == "start") {
            level = getNetIndentLevel(tokens);
        }
        if (level > 0) {
            return indent + tab;
        } else if (level < 0 && indent.substr(indent.length - tab.length) == tab) {
            // Don't do a next-line outdent if we're going to do a real outdent of this line
            if (!this.checkOutdent(state, line, "\n")) {
                return indent.substr(0, indent.length - tab.length);
            }
        }
        return indent;
    };

    this.checkOutdent = function(state, line, input) {
        if (input != "\n" && input != "\r" && input != "\r\n")
            return false;

        if (line.match(/^\s*[\)\}\]]$/))
            return true;

        var tokens = this.$tokenizer.getLineTokens(line.trim(), state).tokens;

        if (!tokens || !tokens.length)
            return false;

        return (tokens[0].type == "keyword" && outdentKeywords.indexOf(tokens[0].value) != -1);
    };

    this.autoOutdent = function(state, session, row) {
        var prevLine = session.getLine(row - 1);
        var prevIndent = this.$getIndent(prevLine).length;
        var prevTokens = this.$tokenizer.getLineTokens(prevLine, "start").tokens;
        var tabLength = session.getTabString().length;
        var expectedIndent = prevIndent + tabLength * getNetIndentLevel(prevTokens);
        var curIndent = this.$getIndent(session.getLine(row)).length;
        if (curIndent < expectedIndent) {
            // User already outdented //
            return;
        }
        session.outdentRows(new Range(row, 0, row + 2, 0));
    };

}).call(Mode.prototype);

exports.Mode = Mode;
});

ace.define('ace/mode/lua_highlight_rules', ['require', 'exports', 'module' , 'ace/lib/oop', 'ace/mode/text_highlight_rules'], function(require, exports, module) {


var oop = require("../lib/oop");
var TextHighlightRules = require("./text_highlight_rules").TextHighlightRules;

var LuaHighlightRules = function() {

    var keywords = (
        "break|do|else|elseif|end|for|function|if|in|local|repeat|"+
         "return|then|until|while|or|and|not"
    );

    var builtinConstants = ("true|false|nil|_G|_VERSION");

    var functions = (
      // builtinFunctions
        "string|xpcall|package|tostring|print|os|unpack|require|"+
        "getfenv|setmetatable|next|assert|tonumber|io|rawequal|"+
        "collectgarbage|getmetatable|module|rawset|math|debug|"+
        "pcall|table|newproxy|type|coroutine|_G|select|gcinfo|"+
        "pairs|rawget|loadstring|ipairs|_VERSION|dofile|setfenv|"+
        "load|error|loadfile|"+

        "sub|upper|len|gfind|rep|find|match|char|dump|gmatch|"+
        "reverse|byte|format|gsub|lower|preload|loadlib|loaded|"+
        "loaders|cpath|config|path|seeall|exit|setlocale|date|"+
        "getenv|difftime|remove|time|clock|tmpname|rename|execute|"+
        "lines|write|close|flush|open|output|type|read|stderr|"+
        "stdin|input|stdout|popen|tmpfile|log|max|acos|huge|"+
        "ldexp|pi|cos|tanh|pow|deg|tan|cosh|sinh|random|randomseed|"+
        "frexp|ceil|floor|rad|abs|sqrt|modf|asin|min|mod|fmod|log10|"+
        "atan2|exp|sin|atan|getupvalue|debug|sethook|getmetatable|"+
        "gethook|setmetatable|setlocal|traceback|setfenv|getinfo|"+
        "setupvalue|getlocal|getregistry|getfenv|setn|insert|getn|"+
        "foreachi|maxn|foreach|concat|sort|remove|resume|yield|"+
        "status|wrap|create|running|"+
      // metatableMethods
        "__add|__sub|__mod|__unm|__concat|__lt|__index|__call|__gc|__metatable|"+
         "__mul|__div|__pow|__len|__eq|__le|__newindex|__tostring|__mode|__tonumber"
    );

    var stdLibaries = ("string|package|os|io|math|debug|table|coroutine");

    var futureReserved = "";

    var deprecatedIn5152 = ("setn|foreach|foreachi|gcinfo|log10|maxn");

    var keywordMapper = this.createKeywordMapper({
        "keyword": keywords,
        "support.function": functions,
        "invalid.deprecated": deprecatedIn5152,
        "constant.library": stdLibaries,
        "constant.language": builtinConstants,
        "invalid.illegal": futureReserved,
        "variable.language": "this"
    }, "identifier");

    var strPre = "";

    var decimalInteger = "(?:(?:[1-9]\\d*)|(?:0))";
    var hexInteger = "(?:0[xX][\\dA-Fa-f]+)";
    var integer = "(?:" + decimalInteger + "|" + hexInteger + ")";

    var fraction = "(?:\\.\\d+)";
    var intPart = "(?:\\d+)";
    var pointFloat = "(?:(?:" + intPart + "?" + fraction + ")|(?:" + intPart + "\\.))";
    var floatNumber = "(?:" + pointFloat + ")";

    var comment_stack = [];

    this.$rules = {
        "start" :


        // bracketed comments
        [{
            token : "comment",           // --[[ comment
            regex : strPre + '\\-\\-\\[\\[.*\\]\\]'
        }, {
            token : "comment",           // --[=[ comment
            regex : strPre + '\\-\\-\\[\\=\\[.*\\]\\=\\]'
        }, {
            token : "comment",           // --[==[ comment
            regex : strPre + '\\-\\-\\[\\={2}\\[.*\\]\\={2}\\]'
        }, {
            token : "comment",           // --[===[ comment
            regex : strPre + '\\-\\-\\[\\={3}\\[.*\\]\\={3}\\]'
        }, {
            token : "comment",           // --[====[ comment
            regex : strPre + '\\-\\-\\[\\={4}\\[.*\\]\\={4}\\]'
        }, {
            token : "comment",           // --[====+[ comment
            regex : strPre + '\\-\\-\\[\\={5}\\=*\\[.*\\]\\={5}\\=*\\]'
        },

        // multiline bracketed comments
        {
            token : "comment",           // --[[ comment
            regex : strPre + '\\-\\-\\[\\[.*$',
            merge : true,
            next  : "qcomment"
        }, {
            token : "comment",           // --[=[ comment
            regex : strPre + '\\-\\-\\[\\=\\[.*$',
            merge : true,
            next  : "qcomment1"
        }, {
            token : "comment",           // --[==[ comment
            regex : strPre + '\\-\\-\\[\\={2}\\[.*$',
            merge : true,
            next  : "qcomment2"
        }, {
            token : "comment",           // --[===[ comment
            regex : strPre + '\\-\\-\\[\\={3}\\[.*$',
            merge : true,
            next  : "qcomment3"
        }, {
            token : "comment",           // --[====[ comment
            regex : strPre + '\\-\\-\\[\\={4}\\[.*$',
            merge : true,
            next  : "qcomment4"
        }, {
            token : function(value){     // --[====+[ comment
                // WARNING: EXTREMELY SLOW, but this is the only way to circumvent the
                // limits imposed by the current automaton.
                // I've never personally seen any practical code where 5 or more '='s are
                // used for string or commenting, so this will rarely be invoked.
                var pattern = /\-\-\[(\=+)\[/, match;
                // you can never be too paranoid ;)
                if ((match = pattern.exec(value)) != null && (match = match[1]) != undefined)
                    comment_stack.push(match.length);

                return "comment";
            },
            regex : strPre + '\\-\\-\\[\\={5}\\=*\\[.*$',
            merge : true,
            next  : "qcomment5"
        },

        // single line comments
        {
            token : "comment",
            regex : "\\-\\-.*$"
        },

        // bracketed strings
        {
            token : "string",           // [[ string
            regex : strPre + '\\[\\[.*\\]\\]'
        }, {
            token : "string",           // [=[ string
            regex : strPre + '\\[\\=\\[.*\\]\\=\\]'
        }, {
            token : "string",           // [==[ string
            regex : strPre + '\\[\\={2}\\[.*\\]\\={2}\\]'
        }, {
            token : "string",           // [===[ string
            regex : strPre + '\\[\\={3}\\[.*\\]\\={3}\\]'
        }, {
            token : "string",           // [====[ string
            regex : strPre + '\\[\\={4}\\[.*\\]\\={4}\\]'
        }, {
            token : "string",           // [====+[ string
            regex : strPre + '\\[\\={5}\\=*\\[.*\\]\\={5}\\=*\\]'
        },

        // multiline bracketed strings
        {
            token : "string",           // [[ string
            regex : strPre + '\\[\\[.*$',
            merge : true,
            next  : "qstring"
        }, {
            token : "string",           // [=[ string
            regex : strPre + '\\[\\=\\[.*$',
            merge : true,
            next  : "qstring1"
        }, {
            token : "string",           // [==[ string
            regex : strPre + '\\[\\={2}\\[.*$',
            merge : true,
            next  : "qstring2"
        }, {
            token : "string",           // [===[ string
            regex : strPre + '\\[\\={3}\\[.*$',
            merge : true,
            next  : "qstring3"
        }, {
            token : "string",           // [====[ string
            regex : strPre + '\\[\\={4}\\[.*$',
            merge : true,
            next  : "qstring4"
        }, {
            token : function(value){     // --[====+[ string
                // WARNING: EXTREMELY SLOW, see above.
                var pattern = /\[(\=+)\[/, match;
                if ((match = pattern.exec(value)) != null && (match = match[1]) != undefined)
                    comment_stack.push(match.length);

                return "string";
            },
            regex : strPre + '\\[\\={5}\\=*\\[.*$',
            merge : true,
            next  : "qstring5"
        },

        {
            token : "string",           // " string
            regex : strPre + '"(?:[^\\\\]|\\\\.)*?"'
        }, {
            token : "string",           // ' string
            regex : strPre + "'(?:[^\\\\]|\\\\.)*?'"
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
            regex : "\\+|\\-|\\*|\\/|%|\\#|\\^|~|<|>|<=|=>|==|~=|=|\\:|\\.\\.\\.|\\.\\."
        }, {
            token : "paren.lparen",
            regex : "[\\[\\(\\{]"
        }, {
            token : "paren.rparen",
            regex : "[\\]\\)\\}]"
        }, {
            token : "text",
            regex : "\\s+"
        } ],

        "qcomment": [ {
            token : "comment",
            regex : "(?:[^\\\\]|\\\\.)*?\\]\\]",
            next  : "start"
        }, {
            token : "comment",
            merge : true,
            regex : '.+'
        } ],
        "qcomment1": [ {
            token : "comment",
            regex : "(?:[^\\\\]|\\\\.)*?\\]\\=\\]",
            next  : "start"
        }, {
            token : "comment",
            merge : true,
            regex : '.+'
        } ],
        "qcomment2": [ {
            token : "comment",
            regex : "(?:[^\\\\]|\\\\.)*?\\]\\={2}\\]",
            next  : "start"
        }, {
            token : "comment",
            merge : true,
            regex : '.+'
        } ],
        "qcomment3": [ {
            token : "comment",
            regex : "(?:[^\\\\]|\\\\.)*?\\]\\={3}\\]",
            next  : "start"
        }, {
            token : "comment",
            merge : true,
            regex : '.+'
        } ],
        "qcomment4": [ {
            token : "comment",
            regex : "(?:[^\\\\]|\\\\.)*?\\]\\={4}\\]",
            next  : "start"
        }, {
            token : "comment",
            merge : true,
            regex : '.+'
        } ],
        "qcomment5": [ {
            token : function(value){
                // very hackish, mutates the qcomment5 field on the fly.
                var pattern = /\](\=+)\]/, rule = this.rules.qcomment5[0], match;
                rule.next = "start";
                if ((match = pattern.exec(value)) != null && (match = match[1]) != undefined){
                    var found = match.length, expected;
                    if ((expected = comment_stack.pop()) != found){
                        comment_stack.push(expected);
                        rule.next = "qcomment5";
                    }
                }

                return "comment";
            },
            regex : "(?:[^\\\\]|\\\\.)*?\\]\\={5}\\=*\\]",
            next  : "start"
        }, {
            token : "comment",
            merge : true,
            regex : '.+'
        } ],

        "qstring": [ {
            token : "string",
            regex : "(?:[^\\\\]|\\\\.)*?\\]\\]",
            next  : "start"
        }, {
            token : "string",
            merge : true,
            regex : '.+'
        } ],
        "qstring1": [ {
            token : "string",
            regex : "(?:[^\\\\]|\\\\.)*?\\]\\=\\]",
            next  : "start"
        }, {
            token : "string",
            merge : true,
            regex : '.+'
        } ],
        "qstring2": [ {
            token : "string",
            regex : "(?:[^\\\\]|\\\\.)*?\\]\\={2}\\]",
            next  : "start"
        }, {
            token : "string",
            merge : true,
            regex : '.+'
        } ],
        "qstring3": [ {
            token : "string",
            regex : "(?:[^\\\\]|\\\\.)*?\\]\\={3}\\]",
            next  : "start"
        }, {
            token : "string",
            merge : true,
            regex : '.+'
        } ],
        "qstring4": [ {
            token : "string",
            regex : "(?:[^\\\\]|\\\\.)*?\\]\\={4}\\]",
            next  : "start"
        }, {
            token : "string",
            merge : true,
            regex : '.+'
        } ],
        "qstring5": [ {
            token : function(value){
                // very hackish, mutates the qstring5 field on the fly.
                var pattern = /\](\=+)\]/, rule = this.rules.qstring5[0], match;
                rule.next = "start";
                if ((match = pattern.exec(value)) != null && (match = match[1]) != undefined){
                    var found = match.length, expected;
                    if ((expected = comment_stack.pop()) != found){
                        comment_stack.push(expected);
                        rule.next = "qstring5";
                    }
                }

                return "string";
            },
            regex : "(?:[^\\\\]|\\\\.)*?\\]\\={5}\\=*\\]",
            next  : "start"
        }, {
            token : "string",
            merge : true,
            regex : '.+'
        } ]

    };

}

oop.inherits(LuaHighlightRules, TextHighlightRules);

exports.LuaHighlightRules = LuaHighlightRules;
});
