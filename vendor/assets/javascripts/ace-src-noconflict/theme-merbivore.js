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

ace.define('ace/theme/merbivore', ['require', 'exports', 'module' , 'ace/lib/dom'], function(require, exports, module) {

exports.isDark = true;
exports.cssClass = "ace-merbivore";
exports.cssText = ".ace-merbivore .ace_gutter {\
background: #202020;\
color: #E6E1DC\
}\
.ace-merbivore .ace_print-margin {\
width: 1px;\
background: #555651\
}\
.ace-merbivore {\
background-color: #161616;\
color: #E6E1DC\
}\
.ace-merbivore .ace_cursor {\
color: #FFFFFF\
}\
.ace-merbivore .ace_marker-layer .ace_selection {\
background: #454545\
}\
.ace-merbivore.ace_multiselect .ace_selection.ace_start {\
box-shadow: 0 0 3px 0px #161616;\
border-radius: 2px\
}\
.ace-merbivore .ace_marker-layer .ace_step {\
background: rgb(102, 82, 0)\
}\
.ace-merbivore .ace_marker-layer .ace_bracket {\
margin: -1px 0 0 -1px;\
border: 1px solid #404040\
}\
.ace-merbivore .ace_marker-layer .ace_active-line {\
background: #333435\
}\
.ace-merbivore .ace_gutter-active-line {\
background-color: #333435\
}\
.ace-merbivore .ace_marker-layer .ace_selected-word {\
border: 1px solid #454545\
}\
.ace-merbivore .ace_invisible {\
color: #404040\
}\
.ace-merbivore .ace_entity.ace_name.ace_tag,\
.ace-merbivore .ace_keyword,\
.ace-merbivore .ace_meta,\
.ace-merbivore .ace_meta.ace_tag,\
.ace-merbivore .ace_storage,\
.ace-merbivore .ace_support.ace_function {\
color: #FC6F09\
}\
.ace-merbivore .ace_constant,\
.ace-merbivore .ace_constant.ace_character,\
.ace-merbivore .ace_constant.ace_character.ace_escape,\
.ace-merbivore .ace_constant.ace_other,\
.ace-merbivore .ace_support.ace_type {\
color: #1EDAFB\
}\
.ace-merbivore .ace_constant.ace_character.ace_escape {\
color: #519F50\
}\
.ace-merbivore .ace_constant.ace_language {\
color: #FDC251\
}\
.ace-merbivore .ace_constant.ace_library,\
.ace-merbivore .ace_string,\
.ace-merbivore .ace_support.ace_constant {\
color: #8DFF0A\
}\
.ace-merbivore .ace_constant.ace_numeric {\
color: #58C554\
}\
.ace-merbivore .ace_invalid {\
color: #FFFFFF;\
background-color: #990000\
}\
.ace-merbivore .ace_fold {\
background-color: #FC6F09;\
border-color: #E6E1DC\
}\
.ace-merbivore .ace_comment {\
font-style: italic;\
color: #AD2EA4\
}\
.ace-merbivore .ace_entity.ace_other.ace_attribute-name {\
color: #FFFF89\
}\
.ace-merbivore .ace_indent-guide {\
background: url(data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAACCAYAAACZgbYnAAAAEklEQVQImWMQFxf3ZXB1df0PAAdsAmERTkEHAAAAAElFTkSuQmCC) right repeat-y;\
}";

var dom = require("../lib/dom");
dom.importCssString(exports.cssText, exports.cssClass);
});
