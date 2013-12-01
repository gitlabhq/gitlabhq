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

ace.define('ace/theme/solarized_dark', ['require', 'exports', 'module' , 'ace/lib/dom'], function(require, exports, module) {

exports.isDark = true;
exports.cssClass = "ace-solarized-dark";
exports.cssText = ".ace-solarized-dark .ace_gutter {\
background: #01313f;\
color: #d0edf7\
}\
.ace-solarized-dark .ace_print-margin {\
width: 1px;\
background: #33555E\
}\
.ace-solarized-dark {\
background-color: #002B36;\
color: #93A1A1\
}\
.ace-solarized-dark .ace_entity.ace_other.ace_attribute-name,\
.ace-solarized-dark .ace_storage {\
color: #93A1A1\
}\
.ace-solarized-dark .ace_cursor {\
color: #D30102\
}\
.ace-solarized-dark .ace_marker-layer .ace_active-line,\
.ace-solarized-dark .ace_marker-layer .ace_selection {\
background: rgba(255, 255, 255, 0.1)\
}\
.ace-solarized-dark.ace_multiselect .ace_selection.ace_start {\
box-shadow: 0 0 3px 0px #002B36;\
border-radius: 2px\
}\
.ace-solarized-dark .ace_marker-layer .ace_step {\
background: rgb(102, 82, 0)\
}\
.ace-solarized-dark .ace_marker-layer .ace_bracket {\
margin: -1px 0 0 -1px;\
border: 1px solid rgba(147, 161, 161, 0.50)\
}\
.ace-solarized-dark .ace_gutter-active-line {\
background-color: #0d3440\
}\
.ace-solarized-dark .ace_marker-layer .ace_selected-word {\
border: 1px solid #073642\
}\
.ace-solarized-dark .ace_invisible {\
color: rgba(147, 161, 161, 0.50)\
}\
.ace-solarized-dark .ace_keyword,\
.ace-solarized-dark .ace_meta,\
.ace-solarized-dark .ace_support.ace_class,\
.ace-solarized-dark .ace_support.ace_type {\
color: #859900\
}\
.ace-solarized-dark .ace_constant.ace_character,\
.ace-solarized-dark .ace_constant.ace_other {\
color: #CB4B16\
}\
.ace-solarized-dark .ace_constant.ace_language {\
color: #B58900\
}\
.ace-solarized-dark .ace_constant.ace_numeric {\
color: #D33682\
}\
.ace-solarized-dark .ace_fold {\
background-color: #268BD2;\
border-color: #93A1A1\
}\
.ace-solarized-dark .ace_entity.ace_name.ace_function,\
.ace-solarized-dark .ace_entity.ace_name.ace_tag,\
.ace-solarized-dark .ace_support.ace_function,\
.ace-solarized-dark .ace_variable,\
.ace-solarized-dark .ace_variable.ace_language {\
color: #268BD2\
}\
.ace-solarized-dark .ace_string {\
color: #2AA198\
}\
.ace-solarized-dark .ace_string.ace_regexp {\
color: #D30102\
}\
.ace-solarized-dark .ace_comment {\
font-style: italic;\
color: #657B83\
}\
.ace-solarized-dark .ace_indent-guide {\
background: url(data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAACCAYAAACZgbYnAAAAEklEQVQImWNg0Db1ZVCxc/sPAAd4AlUHlLenAAAAAElFTkSuQmCC) right repeat-y;\
}";

var dom = require("../lib/dom");
dom.importCssString(exports.cssText, exports.cssClass);
});
