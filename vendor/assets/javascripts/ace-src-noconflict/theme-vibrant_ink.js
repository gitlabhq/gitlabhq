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

ace.define('ace/theme/vibrant_ink', ['require', 'exports', 'module' , 'ace/lib/dom'], function(require, exports, module) {

exports.isDark = true;
exports.cssClass = "ace-vibrant-ink";
exports.cssText = ".ace-vibrant-ink .ace_gutter {\
background: #1a1a1a;\
color: #BEBEBE\
}\
.ace-vibrant-ink .ace_print-margin {\
width: 1px;\
background: #1a1a1a\
}\
.ace-vibrant-ink {\
background-color: #0F0F0F;\
color: #FFFFFF\
}\
.ace-vibrant-ink .ace_cursor {\
color: #FFFFFF\
}\
.ace-vibrant-ink .ace_marker-layer .ace_selection {\
background: #6699CC\
}\
.ace-vibrant-ink.ace_multiselect .ace_selection.ace_start {\
box-shadow: 0 0 3px 0px #0F0F0F;\
border-radius: 2px\
}\
.ace-vibrant-ink .ace_marker-layer .ace_step {\
background: rgb(102, 82, 0)\
}\
.ace-vibrant-ink .ace_marker-layer .ace_bracket {\
margin: -1px 0 0 -1px;\
border: 1px solid #404040\
}\
.ace-vibrant-ink .ace_marker-layer .ace_active-line {\
background: #333333\
}\
.ace-vibrant-ink .ace_gutter-active-line {\
background-color: #333333\
}\
.ace-vibrant-ink .ace_marker-layer .ace_selected-word {\
border: 1px solid #6699CC\
}\
.ace-vibrant-ink .ace_invisible {\
color: #404040\
}\
.ace-vibrant-ink .ace_keyword,\
.ace-vibrant-ink .ace_meta {\
color: #FF6600\
}\
.ace-vibrant-ink .ace_constant,\
.ace-vibrant-ink .ace_constant.ace_character,\
.ace-vibrant-ink .ace_constant.ace_character.ace_escape,\
.ace-vibrant-ink .ace_constant.ace_other {\
color: #339999\
}\
.ace-vibrant-ink .ace_constant.ace_numeric {\
color: #99CC99\
}\
.ace-vibrant-ink .ace_invalid,\
.ace-vibrant-ink .ace_invalid.ace_deprecated {\
color: #CCFF33;\
background-color: #000000\
}\
.ace-vibrant-ink .ace_fold {\
background-color: #FFCC00;\
border-color: #FFFFFF\
}\
.ace-vibrant-ink .ace_entity.ace_name.ace_function,\
.ace-vibrant-ink .ace_support.ace_function,\
.ace-vibrant-ink .ace_variable {\
color: #FFCC00\
}\
.ace-vibrant-ink .ace_variable.ace_parameter {\
font-style: italic\
}\
.ace-vibrant-ink .ace_string {\
color: #66FF00\
}\
.ace-vibrant-ink .ace_string.ace_regexp {\
color: #44B4CC\
}\
.ace-vibrant-ink .ace_comment {\
color: #9933CC\
}\
.ace-vibrant-ink .ace_entity.ace_other.ace_attribute-name {\
font-style: italic;\
color: #99CC99\
}\
.ace-vibrant-ink .ace_indent-guide {\
background: url(data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAACCAYAAACZgbYnAAAAEklEQVQImWNgYGBgYNDTc/oPAALPAZ7hxlbYAAAAAElFTkSuQmCC) right repeat-y;\
}";

var dom = require("../lib/dom");
dom.importCssString(exports.cssText, exports.cssClass);
});
