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

ace.define('ace/theme/solarized_light', ['require', 'exports', 'module' , 'ace/lib/dom'], function(require, exports, module) {

exports.isDark = false;
exports.cssClass = "ace-solarized-light";
exports.cssText = ".ace-solarized-light .ace_gutter {\
background: #fbf1d3;\
color: #333\
}\
.ace-solarized-light .ace_print-margin {\
width: 1px;\
background: #e8e8e8\
}\
.ace-solarized-light {\
background-color: #FDF6E3;\
color: #586E75\
}\
.ace-solarized-light .ace_cursor {\
color: #000000\
}\
.ace-solarized-light .ace_marker-layer .ace_selection {\
background:  rgba(7, 54, 67, 0.09)\
}\
.ace-solarized-light.ace_multiselect .ace_selection.ace_start {\
box-shadow: 0 0 3px 0px #FDF6E3;\
border-radius: 2px\
}\
.ace-solarized-light .ace_marker-layer .ace_step {\
background: rgb(255, 255, 0)\
}\
.ace-solarized-light .ace_marker-layer .ace_bracket {\
margin: -1px 0 0 -1px;\
border: 1px solid rgba(147, 161, 161, 0.50)\
}\
.ace-solarized-light .ace_marker-layer .ace_active-line {\
background: #EEE8D5\
}\
.ace-solarized-light .ace_gutter-active-line {\
background-color : #EDE5C1\
}\
.ace-solarized-light .ace_marker-layer .ace_selected-word {\
border: 1px solid #073642\
}\
.ace-solarized-light .ace_invisible {\
color: rgba(147, 161, 161, 0.50)\
}\
.ace-solarized-light .ace_keyword,\
.ace-solarized-light .ace_meta,\
.ace-solarized-light .ace_support.ace_class,\
.ace-solarized-light .ace_support.ace_type {\
color: #859900\
}\
.ace-solarized-light .ace_constant.ace_character,\
.ace-solarized-light .ace_constant.ace_other {\
color: #CB4B16\
}\
.ace-solarized-light .ace_constant.ace_language {\
color: #B58900\
}\
.ace-solarized-light .ace_constant.ace_numeric {\
color: #D33682\
}\
.ace-solarized-light .ace_fold {\
background-color: #268BD2;\
border-color: #586E75\
}\
.ace-solarized-light .ace_entity.ace_name.ace_function,\
.ace-solarized-light .ace_entity.ace_name.ace_tag,\
.ace-solarized-light .ace_support.ace_function,\
.ace-solarized-light .ace_variable,\
.ace-solarized-light .ace_variable.ace_language {\
color: #268BD2\
}\
.ace-solarized-light .ace_storage {\
color: #073642\
}\
.ace-solarized-light .ace_string {\
color: #2AA198\
}\
.ace-solarized-light .ace_string.ace_regexp {\
color: #D30102\
}\
.ace-solarized-light .ace_comment,\
.ace-solarized-light .ace_entity.ace_other.ace_attribute-name {\
color: #93A1A1\
}\
.ace-solarized-light .ace_indent-guide {\
background: url(data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAACCAYAAACZgbYnAAAAEklEQVQImWNgYGBgYHjy8NJ/AAjgA5fzQUmBAAAAAElFTkSuQmCC) right repeat-y;\
}";

var dom = require("../lib/dom");
dom.importCssString(exports.cssText, exports.cssClass);
});
