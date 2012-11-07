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

ace.define('ace/theme/kr_theme', ['require', 'exports', 'module', 'ace/lib/dom'], function(require, exports, module) {

exports.isDark = true;
exports.cssClass = "ace-kr-theme";
exports.cssText = ".ace-kr-theme .ace_editor {\
  border: 2px solid rgb(159, 159, 159)\
}\
\
.ace-kr-theme .ace_editor.ace_focus {\
  border: 2px solid #327fbd\
}\
\
.ace-kr-theme .ace_gutter {\
  background: #1c1917;\
  color: #FCFFE0\
}\
\
.ace-kr-theme .ace_print_margin {\
  width: 1px;\
  background: #1c1917\
}\
\
.ace-kr-theme .ace_scroller {\
  background-color: #0B0A09\
}\
\
.ace-kr-theme .ace_text-layer {\
  color: #FCFFE0\
}\
\
.ace-kr-theme .ace_cursor {\
  border-left: 2px solid #FF9900\
}\
\
.ace-kr-theme .ace_cursor.ace_overwrite {\
  border-left: 0px;\
  border-bottom: 1px solid #FF9900\
}\
\
.ace-kr-theme .ace_marker-layer .ace_selection {\
  background: rgba(170, 0, 255, 0.45)\
}\
\
.ace-kr-theme.multiselect .ace_selection.start {\
  box-shadow: 0 0 3px 0px #0B0A09;\
  border-radius: 2px\
}\
\
.ace-kr-theme .ace_marker-layer .ace_step {\
  background: rgb(102, 82, 0)\
}\
\
.ace-kr-theme .ace_marker-layer .ace_bracket {\
  margin: -1px 0 0 -1px;\
  border: 1px solid rgba(255, 177, 111, 0.32)\
}\
\
.ace-kr-theme .ace_marker-layer .ace_active_line {\
  background: #38403D\
}\
\
.ace-kr-theme .ace_gutter_active_line {\
  background-color : #38403D\
}\
\
.ace-kr-theme .ace_marker-layer .ace_selected_word {\
  border: 1px solid rgba(170, 0, 255, 0.45)\
}\
\
.ace-kr-theme .ace_invisible {\
  color: rgba(255, 177, 111, 0.32)\
}\
\
.ace-kr-theme .ace_keyword,\
.ace-kr-theme .ace_meta {\
  color: #949C8B\
}\
\
.ace-kr-theme .ace_constant,\
.ace-kr-theme .ace_constant.ace_character,\
.ace-kr-theme .ace_constant.ace_character.ace_escape,\
.ace-kr-theme .ace_constant.ace_other {\
  color: rgba(210, 117, 24, 0.76)\
}\
\
.ace-kr-theme .ace_invalid {\
  color: #F8F8F8;\
  background-color: #A41300\
}\
\
.ace-kr-theme .ace_support {\
  color: #9FC28A\
}\
\
.ace-kr-theme .ace_support.ace_constant {\
  color: #C27E66\
}\
\
.ace-kr-theme .ace_fold {\
  background-color: #949C8B;\
  border-color: #FCFFE0\
}\
\
.ace-kr-theme .ace_support.ace_function {\
  color: #85873A\
}\
\
.ace-kr-theme .ace_storage {\
  color: #FFEE80\
}\
\
.ace-kr-theme .ace_string.ace_regexp {\
  color: rgba(125, 255, 192, 0.65)\
}\
\
.ace-kr-theme .ace_comment {\
  font-style: italic;\
  color: #706D5B\
}\
\
.ace-kr-theme .ace_variable {\
  color: #D1A796\
}\
\
.ace-kr-theme .ace_variable.ace_language {\
  color: #FF80E1\
}\
\
.ace-kr-theme .ace_meta.ace_tag {\
  color: #BABD9C\
}\
\
.ace-kr-theme .ace_markup.ace_underline {\
  text-decoration: underline\
}\
\
.ace-kr-theme .ace_markup.ace_list {\
  background-color: #0F0040\
}\
\
.ace-kr-theme .ace_indent-guide {\
  background: url(data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAACCAYAAACZgbYnAAAAEklEQVQImWPg5uL8zzBz5sz/AA1WA+hUYIqjAAAAAElFTkSuQmCC) right repeat-y\
}";

var dom = require("../lib/dom");
dom.importCssString(exports.cssText, exports.cssClass);
});
