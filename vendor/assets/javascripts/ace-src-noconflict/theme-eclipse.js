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

ace.define('ace/theme/eclipse', ['require', 'exports', 'module' , 'ace/lib/dom'], function(require, exports, module) {


exports.isDark = false;
exports.cssText = ".ace-eclipse .ace_gutter {\
background: #ebebeb;\
border-right: 1px solid rgb(159, 159, 159);\
color: rgb(136, 136, 136);\
}\
.ace-eclipse .ace_print-margin {\
width: 1px;\
background: #ebebeb;\
}\
.ace-eclipse {\
background-color: #FFFFFF;\
}\
.ace-eclipse .ace_fold {\
background-color: rgb(60, 76, 114);\
}\
.ace-eclipse .ace_cursor {\
color: black;\
}\
.ace-eclipse .ace_storage,\
.ace-eclipse .ace_keyword,\
.ace-eclipse .ace_variable {\
color: rgb(127, 0, 85);\
}\
.ace-eclipse .ace_constant.ace_buildin {\
color: rgb(88, 72, 246);\
}\
.ace-eclipse .ace_constant.ace_library {\
color: rgb(6, 150, 14);\
}\
.ace-eclipse .ace_function {\
color: rgb(60, 76, 114);\
}\
.ace-eclipse .ace_string {\
color: rgb(42, 0, 255);\
}\
.ace-eclipse .ace_comment {\
color: rgb(113, 150, 130);\
}\
.ace-eclipse .ace_comment.ace_doc {\
color: rgb(63, 95, 191);\
}\
.ace-eclipse .ace_comment.ace_doc.ace_tag {\
color: rgb(127, 159, 191);\
}\
.ace-eclipse .ace_constant.ace_numeric {\
color: darkblue;\
}\
.ace-eclipse .ace_tag {\
color: rgb(25, 118, 116);\
}\
.ace-eclipse .ace_type {\
color: rgb(127, 0, 127);\
}\
.ace-eclipse .ace_xml-pe {\
color: rgb(104, 104, 91);\
}\
.ace-eclipse .ace_marker-layer .ace_selection {\
background: rgb(181, 213, 255);\
}\
.ace-eclipse .ace_marker-layer .ace_bracket {\
margin: -1px 0 0 -1px;\
border: 1px solid rgb(192, 192, 192);\
}\
.ace-eclipse .ace_meta.ace_tag {\
color:rgb(25, 118, 116);\
}\
.ace-eclipse .ace_invisible {\
color: #ddd;\
}\
.ace-eclipse .ace_entity.ace_other.ace_attribute-name {\
color:rgb(127, 0, 127);\
}\
.ace-eclipse .ace_marker-layer .ace_step {\
background: rgb(255, 255, 0);\
}\
.ace-eclipse .ace_marker-layer .ace_active-line {\
background: rgb(232, 242, 254);\
}\
.ace-eclipse .ace_marker-layer .ace_selected-word {\
border: 1px solid rgb(181, 213, 255);\
}\
.ace-eclipse .ace_indent-guide {\
background: url(\"data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAACCAYAAACZgbYnAAAAE0lEQVQImWP4////f4bLly//BwAmVgd1/w11/gAAAABJRU5ErkJggg==\") right repeat-y;\
}";

exports.cssClass = "ace-eclipse";

var dom = require("../lib/dom");
dom.importCssString(exports.cssText, exports.cssClass);
});
