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

ace.define('ace/theme/terminal', ['require', 'exports', 'module' , 'ace/lib/dom'], function(require, exports, module) {

exports.isDark = true;
exports.cssClass = "ace-terminal-theme";
exports.cssText = ".ace-terminal-theme .ace_gutter {\
background: #1a0005;\
color: steelblue\
}\
.ace-terminal-theme .ace_print-margin {\
width: 1px;\
background: #1a1a1a\
}\
.ace-terminal-theme {\
background-color: black;\
color: #DEDEDE\
}\
.ace-terminal-theme .ace_cursor {\
color: #9F9F9F\
}\
.ace-terminal-theme .ace_marker-layer .ace_selection {\
background: #424242\
}\
.ace-terminal-theme.ace_multiselect .ace_selection.ace_start {\
box-shadow: 0 0 3px 0px black;\
border-radius: 2px\
}\
.ace-terminal-theme .ace_marker-layer .ace_step {\
background: rgb(0, 0, 0)\
}\
.ace-terminal-theme .ace_marker-layer .ace_bracket {\
background: #090;\
}\
.ace-terminal-theme .ace_marker-layer .ace_bracket-start {\
background: #090;\
}\
.ace-terminal-theme .ace_marker-layer .ace_bracket-unmatched {\
margin: -1px 0 0 -1px;\
border: 1px solid #900\
}\
.ace-terminal-theme .ace_marker-layer .ace_active-line {\
background: #2A2A2A\
}\
.ace-terminal-theme .ace_gutter-active-line {\
background-color: #2A112A\
}\
.ace-terminal-theme .ace_marker-layer .ace_selected-word {\
border: 1px solid #424242\
}\
.ace-terminal-theme .ace_invisible {\
color: #343434\
}\
.ace-terminal-theme .ace_keyword,\
.ace-terminal-theme .ace_meta,\
.ace-terminal-theme .ace_storage,\
.ace-terminal-theme .ace_storage.ace_type,\
.ace-terminal-theme .ace_support.ace_type {\
color: tomato\
}\
.ace-terminal-theme .ace_keyword.ace_operator {\
color: deeppink\
}\
.ace-terminal-theme .ace_constant.ace_character,\
.ace-terminal-theme .ace_constant.ace_language,\
.ace-terminal-theme .ace_constant.ace_numeric,\
.ace-terminal-theme .ace_keyword.ace_other.ace_unit,\
.ace-terminal-theme .ace_support.ace_constant,\
.ace-terminal-theme .ace_variable.ace_parameter {\
color: #E78C45\
}\
.ace-terminal-theme .ace_constant.ace_other {\
color: gold\
}\
.ace-terminal-theme .ace_invalid {\
color: yellow;\
background-color: red\
}\
.ace-terminal-theme .ace_invalid.ace_deprecated {\
color: #CED2CF;\
background-color: #B798BF\
}\
.ace-terminal-theme .ace_fold {\
background-color: #7AA6DA;\
border-color: #DEDEDE\
}\
.ace-terminal-theme .ace_entity.ace_name.ace_function,\
.ace-terminal-theme .ace_support.ace_function,\
.ace-terminal-theme .ace_variable {\
color: #7AA6DA\
}\
.ace-terminal-theme .ace_support.ace_class,\
.ace-terminal-theme .ace_support.ace_type {\
color: #E7C547\
}\
.ace-terminal-theme .ace_heading,\
.ace-terminal-theme .ace_string {\
color: #B9CA4A\
}\
.ace-terminal-theme .ace_entity.ace_name.ace_tag,\
.ace-terminal-theme .ace_entity.ace_other.ace_attribute-name,\
.ace-terminal-theme .ace_meta.ace_tag,\
.ace-terminal-theme .ace_string.ace_regexp,\
.ace-terminal-theme .ace_variable {\
color: #D54E53\
}\
.ace-terminal-theme .ace_comment {\
color: orangered\
}\
.ace-terminal-theme .ace_indent-guide {\
background: url(data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAACCAYAAACZgbYnAAAAEklEQVQImWNgYGBgYLBWV/8PAAK4AYnhiq+xAAAAAElFTkSuQmCC) right repeat-y;\
}\
";

var dom = require("../lib/dom");
dom.importCssString(exports.cssText, exports.cssClass);
});
