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

ace.define('ace/keyboard/vim', ['require', 'exports', 'module' , 'ace/keyboard/vim/commands', 'ace/keyboard/vim/maps/util', 'ace/lib/useragent'], function(require, exports, module) {


var cmds = require("./vim/commands");
var coreCommands = cmds.coreCommands;
var util = require("./vim/maps/util");
var useragent = require("../lib/useragent");

var startCommands = {
    "i": {
        command: coreCommands.start
    },
    "I": {
        command: coreCommands.startBeginning
    },
    "a": {
        command: coreCommands.append
    },
    "A": {
        command: coreCommands.appendEnd
    },
    "ctrl-f": {
        command: "gotopagedown"
    },
    "ctrl-b": {
        command: "gotopageup"
    }
};

exports.handler = {
	$id: "ace/keyboard/vim",
    handleMacRepeat: function(data, hashId, key) {
        if (hashId == -1) {
            data.inputChar = key;
            data.lastEvent = "input";
        } else if (data.inputChar && data.$lastHash == hashId && data.$lastKey == key) {
            if (data.lastEvent == "input") {
                data.lastEvent = "input1";
            } else if (data.lastEvent == "input1") {
                return true;
            }
        } else {
            data.$lastHash = hashId;
            data.$lastKey = key;
            data.lastEvent = "keypress";
        }
    },
    updateMacCompositionHandlers: function(editor, enable) {
        var onCompositionUpdateOverride = function(text) {
            if (util.currentMode !== "insert") {
                var el = this.textInput.getElement();
                el.blur();
                el.focus();
                el.value = text;
            } else {
                this.onCompositionUpdateOrig(text);
            }
        };
        var onCompositionStartOverride = function(text) {
            if (util.currentMode === "insert") {            
                this.onCompositionStartOrig(text);
            }
        }
        if (enable) {
            if (!editor.onCompositionUpdateOrig) {
                editor.onCompositionUpdateOrig = editor.onCompositionUpdate;
                editor.onCompositionUpdate = onCompositionUpdateOverride;
                editor.onCompositionStartOrig = editor.onCompositionStart;
                editor.onCompositionStart = onCompositionStartOverride;
            }
        } else {
            if (editor.onCompositionUpdateOrig) {
                editor.onCompositionUpdate = editor.onCompositionUpdateOrig;
                editor.onCompositionUpdateOrig = null;
                editor.onCompositionStart = editor.onCompositionStartOrig;
                editor.onCompositionStartOrig = null;
            }
        }
    },

    handleKeyboard: function(data, hashId, key, keyCode, e) {
        if (hashId != 0 && (key == "" || key == "\x00"))
            return null;
        
        var editor = data.editor;
        
        if (hashId == 1)
            key = "ctrl-" + key;
        if (key == "ctrl-c") {
            if (!useragent.isMac && editor.getCopyText()) {
                editor.once("copy", function() {
                    if (data.state == "start")
                        coreCommands.stop.exec(editor);
                    else
                        editor.selection.clearSelection();
                });
                return {command: "null", passEvent: true};
            }
            return {command: coreCommands.stop};            
        } else if ((key == "esc" && hashId == 0) || key == "ctrl-[") {
            return {command: coreCommands.stop};
        } else if (data.state == "start") {
            if (useragent.isMac && this.handleMacRepeat(data, hashId, key)) {
                hashId = -1;
                key = data.inputChar;
            }
            
            if (hashId == -1 || hashId == 1 || hashId == 0 && key.length > 1) {
                if (cmds.inputBuffer.idle && startCommands[key])
                    return startCommands[key];
                cmds.inputBuffer.push(editor, key);
                return {command: "null", passEvent: false}; 
            } // if no modifier || shift: wait for input.
            else if (key.length == 1 && (hashId == 0 || hashId == 4)) {
                return {command: "null", passEvent: true};
            } else if (key == "esc" && hashId == 0) {
                return {command: coreCommands.stop};
            }
        } else {
            if (key == "ctrl-w") {
                return {command: "removewordleft"};
            }
        }
    },

    attach: function(editor) {
        editor.on("click", exports.onCursorMove);
        if (util.currentMode !== "insert")
            cmds.coreCommands.stop.exec(editor);
        editor.$vimModeHandler = this;
        
        this.updateMacCompositionHandlers(editor, true);
    },

    detach: function(editor) {
        editor.removeListener("click", exports.onCursorMove);
        util.noMode(editor);
        util.currentMode = "normal";
        this.updateMacCompositionHandlers(editor, false);
    },

    actions: cmds.actions,
    getStatusText: function() {
        if (util.currentMode == "insert")
            return "INSERT";
        if (util.onVisualMode)
            return (util.onVisualLineMode ? "VISUAL LINE " : "VISUAL ") + cmds.inputBuffer.status;
        return cmds.inputBuffer.status;
    }
};


exports.onCursorMove = function(e) {
    cmds.onCursorMove(e.editor, e);
    exports.onCursorMove.scheduled = false;
};

});
 
ace.define('ace/keyboard/vim/commands', ['require', 'exports', 'module' , 'ace/lib/lang', 'ace/keyboard/vim/maps/util', 'ace/keyboard/vim/maps/motions', 'ace/keyboard/vim/maps/operators', 'ace/keyboard/vim/maps/aliases', 'ace/keyboard/vim/registers'], function(require, exports, module) {

"never use strict";

var lang = require("../../lib/lang");
var util = require("./maps/util");
var motions = require("./maps/motions");
var operators = require("./maps/operators");
var alias = require("./maps/aliases");
var registers = require("./registers");

var NUMBER = 1;
var OPERATOR = 2;
var MOTION = 3;
var ACTION = 4;
var HMARGIN = 8; // Minimum amount of line separation between margins;

var repeat = function repeat(fn, count, args) {
    while (0 < count--)
        fn.apply(this, args);
};

var ensureScrollMargin = function(editor) {
    var renderer = editor.renderer;
    var pos = renderer.$cursorLayer.getPixelPosition();

    var top = pos.top;

    var margin = HMARGIN * renderer.layerConfig.lineHeight;
    if (2 * margin > renderer.$size.scrollerHeight)
        margin = renderer.$size.scrollerHeight / 2;

    if (renderer.scrollTop > top - margin) {
        renderer.session.setScrollTop(top - margin);
    }

    if (renderer.scrollTop + renderer.$size.scrollerHeight < top + margin + renderer.lineHeight) {
        renderer.session.setScrollTop(top + margin + renderer.lineHeight - renderer.$size.scrollerHeight);
    }
};

var actions = exports.actions = {
    "z": {
        param: true,
        fn: function(editor, range, count, param) {
            switch (param) {
                case "z":
                    editor.renderer.alignCursor(null, 0.5);
                    break;
                case "t":
                    editor.renderer.alignCursor(null, 0);
                    break;
                case "b":
                    editor.renderer.alignCursor(null, 1);
                    break;
                case "c":
                    editor.session.onFoldWidgetClick(range.start.row, {domEvent:{target :{}}});
                    break;
                case "o":
                    editor.session.onFoldWidgetClick(range.start.row, {domEvent:{target :{}}});
                    break;
                case "C":
                    editor.session.foldAll();
                    break;
                case "O":
                    editor.session.unfold();
                    break;
            }
        }
    },
    "r": {
        param: true,
        fn: function(editor, range, count, param) {
            if (param && param.length) {
                if (param.length > 1)
                    param = param == "return" ? "\n" : param == "tab" ? "\t" : param;
                repeat(function() { editor.insert(param); }, count || 1);
                editor.navigateLeft();
            }
        }
    },
    "R": {
        fn: function(editor, range, count, param) {
            util.insertMode(editor);
            editor.setOverwrite(true);
        }
    },
    "~": {
        fn: function(editor, range, count) {
            repeat(function() {
                var range = editor.selection.getRange();
                if (range.isEmpty())
                    range.end.column++;
                var text = editor.session.getTextRange(range);
                var toggled = text.toUpperCase();
                if (toggled == text)
                    editor.navigateRight();
                else
                    editor.session.replace(range, toggled);
            }, count || 1);
        }
    },
    "*": {
        fn: function(editor, range, count, param) {
            editor.selection.selectWord();
            editor.findNext();
            ensureScrollMargin(editor);
            var r = editor.selection.getRange();
            editor.selection.setSelectionRange(r, true);
        }
    },
    "#": {
        fn: function(editor, range, count, param) {
            editor.selection.selectWord();
            editor.findPrevious();
            ensureScrollMargin(editor);
            var r = editor.selection.getRange();
            editor.selection.setSelectionRange(r, true);
        }
    },
    "m": {
        param: true,
        fn: function(editor, range, count, param) {
            var s =  editor.session;
            var markers = s.vimMarkers || (s.vimMarkers = {});
            var c = editor.getCursorPosition();
            if (!markers[param]) {
                markers[param] = editor.session.doc.createAnchor(c);
            }
            markers[param].setPosition(c.row, c.column, true);
        }
    },
    "n": {
        fn: function(editor, range, count, param) {
            var options = editor.getLastSearchOptions();
            options.backwards = false;

            editor.selection.moveCursorRight();
            editor.selection.clearSelection();
            editor.findNext(options);

            ensureScrollMargin(editor);
            var r = editor.selection.getRange();
            r.end.row = r.start.row;
            r.end.column = r.start.column;
            editor.selection.setSelectionRange(r, true);
        }
    },
    "N": {
        fn: function(editor, range, count, param) {
            var options = editor.getLastSearchOptions();
            options.backwards = true;

            editor.findPrevious(options);
            ensureScrollMargin(editor);
            var r = editor.selection.getRange();
            r.end.row = r.start.row;
            r.end.column = r.start.column;
            editor.selection.setSelectionRange(r, true);
        }
    },
    "v": {
        fn: function(editor, range, count, param) {
            editor.selection.selectRight();
            util.visualMode(editor, false);
        },
        acceptsMotion: true
    },
    "V": {
        fn: function(editor, range, count, param) {
            var row = editor.getCursorPosition().row;
            editor.selection.clearSelection();
            editor.selection.moveCursorTo(row, 0);
            editor.selection.selectLineEnd();
            editor.selection.visualLineStart = row;

            util.visualMode(editor, true);
        },
        acceptsMotion: true
    },
    "Y": {
        fn: function(editor, range, count, param) {
            util.copyLine(editor);
        }
    },
    "p": {
        fn: function(editor, range, count, param) {
            var defaultReg = registers._default;

            editor.setOverwrite(false);
            if (defaultReg.isLine) {
                var pos = editor.getCursorPosition();
                pos.column = editor.session.getLine(pos.row).length;
                var text = lang.stringRepeat("\n" + defaultReg.text, count || 1);
                editor.session.insert(pos, text);
                editor.moveCursorTo(pos.row + 1, 0);
            }
            else {
                editor.navigateRight();
                editor.insert(lang.stringRepeat(defaultReg.text, count || 1));
                editor.navigateLeft();
            }
            editor.setOverwrite(true);
            editor.selection.clearSelection();
        }
    },
    "P": {
        fn: function(editor, range, count, param) {
            var defaultReg = registers._default;
            editor.setOverwrite(false);

            if (defaultReg.isLine) {
                var pos = editor.getCursorPosition();
                pos.column = 0;
                var text = lang.stringRepeat(defaultReg.text + "\n", count || 1);
                editor.session.insert(pos, text);
                editor.moveCursorToPosition(pos);
            }
            else {
                editor.insert(lang.stringRepeat(defaultReg.text, count || 1));
            }
            editor.setOverwrite(true);
            editor.selection.clearSelection();
        }
    },
    "J": {
        fn: function(editor, range, count, param) {
            var session = editor.session;
            range = editor.getSelectionRange();
            var pos = {row: range.start.row, column: range.start.column};
            count = count || range.end.row - range.start.row;
            var maxRow = Math.min(pos.row + (count || 1), session.getLength() - 1);

            range.start.column = session.getLine(pos.row).length;
            range.end.column = session.getLine(maxRow).length;
            range.end.row = maxRow;

            var text = "";
            for (var i = pos.row; i < maxRow; i++) {
                var nextLine = session.getLine(i + 1);
                text += " " + /^\s*(.*)$/.exec(nextLine)[1] || "";
            }

            session.replace(range, text);
            editor.moveCursorTo(pos.row, pos.column);
        }
    },
    "u": {
        fn: function(editor, range, count, param) {
            count = parseInt(count || 1, 10);
            for (var i = 0; i < count; i++) {
                editor.undo();
            }
            editor.selection.clearSelection();
        }
    },
    "ctrl-r": {
        fn: function(editor, range, count, param) {
            count = parseInt(count || 1, 10);
            for (var i = 0; i < count; i++) {
                editor.redo();
            }
            editor.selection.clearSelection();
        }
    },
    ":": {
        fn: function(editor, range, count, param) {
            var val = ":";
            if (count > 1)
                val = ".,.+" + count + val;
            if (editor.showCommandLine)
                editor.showCommandLine(val);
        }
    },
    "/": {
        fn: function(editor, range, count, param) {
            if (editor.showCommandLine)
                editor.showCommandLine("/");
        }
    },
    "?": {
        fn: function(editor, range, count, param) {
            if (editor.showCommandLine)
                editor.showCommandLine("?");
        }
    },
    ".": {
        fn: function(editor, range, count, param) {
            util.onInsertReplaySequence = inputBuffer.lastInsertCommands;
            var previous = inputBuffer.previous;
            if (previous) // If there is a previous action
                inputBuffer.exec(editor, previous.action, previous.param);
        }
    },
    "ctrl-x": {
        fn: function(editor, range, count, param) {
            editor.modifyNumber(-(count || 1));
        }
    },
    "ctrl-a": {
        fn: function(editor, range, count, param) {
            editor.modifyNumber(count || 1);
        }
    }
};

var inputBuffer = exports.inputBuffer = {
    accepting: [NUMBER, OPERATOR, MOTION, ACTION],
    currentCmd: null,
    currentCount: "",
    status: "",
    operator: null,
    motion: null,

    lastInsertCommands: [],

    push: function(editor, ch, keyId) {
        var status = this.status;
        var isKeyHandled = true;
        this.idle = false;
        var wObj = this.waitingForParam;
        if (/^numpad\d+$/i.test(ch))
            ch = ch.substr(6);
            
        if (wObj) {
            this.exec(editor, wObj, ch);
        }
        else if (!(ch === "0" && !this.currentCount.length) &&
            (/^\d+$/.test(ch) && this.isAccepting(NUMBER))) {
            this.currentCount += ch;
            this.currentCmd = NUMBER;
            this.accepting = [NUMBER, OPERATOR, MOTION, ACTION];
        }
        else if (!this.operator && this.isAccepting(OPERATOR) && operators[ch]) {
            this.operator = {
                ch: ch,
                count: this.getCount()
            };
            this.currentCmd = OPERATOR;
            this.accepting = [NUMBER, MOTION, ACTION];
            this.exec(editor, { operator: this.operator });
        }
        else if (motions[ch] && this.isAccepting(MOTION)) {
            this.currentCmd = MOTION;

            var ctx = {
                operator: this.operator,
                motion: {
                    ch: ch,
                    count: this.getCount()
                }
            };

            if (motions[ch].param)
                this.waitForParam(ctx);
            else
                this.exec(editor, ctx);
        }
        else if (alias[ch] && this.isAccepting(MOTION)) {
            alias[ch].operator.count = this.getCount();
            this.exec(editor, alias[ch]);
        }
        else if (actions[ch] && this.isAccepting(ACTION)) {
            var actionObj = {
                action: {
                    fn: actions[ch].fn,
                    count: this.getCount()
                }
            };

            if (actions[ch].param) {
                this.waitForParam(actionObj);
            }
            else {
                this.exec(editor, actionObj);
            }

            if (actions[ch].acceptsMotion)
                this.idle = false;
        }
        else if (this.operator) {
            this.operator.count = this.getCount();
            this.exec(editor, { operator: this.operator }, ch);
        }
        else {
            isKeyHandled = ch.length == 1;
            this.reset();
        }
        
        if (this.waitingForParam || this.motion || this.operator) {
            this.status += ch;
        } else if (this.currentCount) {
            this.status = this.currentCount;
        } else if (this.status) {
            this.status = "";
        }
        if (this.status != status)
            editor._emit("changeStatus");
        return isKeyHandled;
    },

    waitForParam: function(cmd) {
        this.waitingForParam = cmd;
    },

    getCount: function() {
        var count = this.currentCount;
        this.currentCount = "";
        return count && parseInt(count, 10);
    },

    exec: function(editor, action, param) {
        var m = action.motion;
        var o = action.operator;
        var a = action.action;

        if (!param)
            param = action.param;

        if (o) {
            this.previous = {
                action: action,
                param: param
            };
        }

        if (o && !editor.selection.isEmpty()) {
            if (operators[o.ch].selFn) {
                operators[o.ch].selFn(editor, editor.getSelectionRange(), o.count, param);
                this.reset();
            }
            return;
        }
        else if (!m && !a && o && param) {
            operators[o.ch].fn(editor, null, o.count, param);
            this.reset();
        }
        else if (m) {
            var run = function(fn) {
                if (fn && typeof fn === "function") { // There should always be a motion
                    if (m.count && !motionObj.handlesCount)
                        repeat(fn, m.count, [editor, null, m.count, param]);
                    else
                        fn(editor, null, m.count, param);
                }
            };

            var motionObj = motions[m.ch];
            var selectable = motionObj.sel;

            if (!o) {
                if ((util.onVisualMode || util.onVisualLineMode) && selectable)
                    run(motionObj.sel);
                else
                    run(motionObj.nav);
            }
            else if (selectable) {
                repeat(function() {
                    run(motionObj.sel);
                    operators[o.ch].fn(editor, editor.getSelectionRange(), o.count, param);
                }, o.count || 1);
            }
            this.reset();
        }
        else if (a) {
            a.fn(editor, editor.getSelectionRange(), a.count, param);
            this.reset();
        }
        handleCursorMove(editor);
    },

    isAccepting: function(type) {
        return this.accepting.indexOf(type) !== -1;
    },

    reset: function() {
        this.operator = null;
        this.motion = null;
        this.currentCount = "";
        this.status = "";
        this.accepting = [NUMBER, OPERATOR, MOTION, ACTION];
        this.idle = true;
        this.waitingForParam = null;
    }
};

function setPreviousCommand(fn) {
    inputBuffer.previous = { action: { action: { fn: fn } } };
}

exports.coreCommands = {
    start: {
        exec: function start(editor) {
            util.insertMode(editor);
            setPreviousCommand(start);
        }
    },
    startBeginning: {
        exec: function startBeginning(editor) {
            editor.navigateLineStart();
            util.insertMode(editor);
            setPreviousCommand(startBeginning);
        }
    },
    stop: {
        exec: function stop(editor) {
            inputBuffer.reset();
            util.onVisualMode = false;
            util.onVisualLineMode = false;
            inputBuffer.lastInsertCommands = util.normalMode(editor);
        }
    },
    append: {
        exec: function append(editor) {
            var pos = editor.getCursorPosition();
            var lineLen = editor.session.getLine(pos.row).length;
            if (lineLen)
                editor.navigateRight();
            util.insertMode(editor);
            setPreviousCommand(append);
        }
    },
    appendEnd: {
        exec: function appendEnd(editor) {
            editor.navigateLineEnd();
            util.insertMode(editor);
            setPreviousCommand(appendEnd);
        }
    }
};

var handleCursorMove = exports.onCursorMove = function(editor, e) {
    if (util.currentMode === 'insert' || handleCursorMove.running)
        return;
    else if(!editor.selection.isEmpty()) {
        handleCursorMove.running = true;
        if (util.onVisualLineMode) {
            var originRow = editor.selection.visualLineStart;
            var cursorRow = editor.getCursorPosition().row;
            if(originRow <= cursorRow) {
                var endLine = editor.session.getLine(cursorRow);
                editor.selection.clearSelection();
                editor.selection.moveCursorTo(originRow, 0);
                editor.selection.selectTo(cursorRow, endLine.length);
            } else {
                var endLine = editor.session.getLine(originRow);
                editor.selection.clearSelection();
                editor.selection.moveCursorTo(originRow, endLine.length);
                editor.selection.selectTo(cursorRow, 0);
            }
        }
        handleCursorMove.running = false;
        return;
    }
    else {
        if (e && (util.onVisualLineMode || util.onVisualMode)) {
            editor.selection.clearSelection();
            util.normalMode(editor);
        }

        handleCursorMove.running = true;
        var pos = editor.getCursorPosition();
        var lineLen = editor.session.getLine(pos.row).length;

        if (lineLen && pos.column === lineLen)
            editor.navigateLeft();
        handleCursorMove.running = false;
    }
};
});
ace.define('ace/keyboard/vim/maps/util', ['require', 'exports', 'module' , 'ace/keyboard/vim/registers', 'ace/lib/dom'], function(require, exports, module) {
var registers = require("../registers");

var dom = require("../../../lib/dom");
dom.importCssString('.insert-mode .ace_cursor{\
    border-left: 2px solid #333333;\
}\
.ace_dark.insert-mode .ace_cursor{\
    border-left: 2px solid #eeeeee;\
}\
.normal-mode .ace_cursor{\
    border: 0!important;\
    background-color: red;\
    opacity: 0.5;\
}', 'vimMode');

module.exports = {
    onVisualMode: false,
    onVisualLineMode: false,
    currentMode: 'normal',
    noMode: function(editor) {
        editor.unsetStyle('insert-mode');
        editor.unsetStyle('normal-mode');
        if (editor.commands.recording)
            editor.commands.toggleRecording(editor);
        editor.setOverwrite(false);
    },
    insertMode: function(editor) {
        this.currentMode = 'insert';
        editor.setStyle('insert-mode');
        editor.unsetStyle('normal-mode');

        editor.setOverwrite(false);
        editor.keyBinding.$data.buffer = "";
        editor.keyBinding.$data.state = "insertMode";
        this.onVisualMode = false;
        this.onVisualLineMode = false;
        if(this.onInsertReplaySequence) {
            editor.commands.macro = this.onInsertReplaySequence;
            editor.commands.replay(editor);
            this.onInsertReplaySequence = null;
            this.normalMode(editor);
        } else {
            editor._emit("changeStatus");
            if(!editor.commands.recording)
                editor.commands.toggleRecording(editor);
        }
    },
    normalMode: function(editor) {
        this.currentMode = 'normal';

        editor.unsetStyle('insert-mode');
        editor.setStyle('normal-mode');
        editor.clearSelection();

        var pos;
        if (!editor.getOverwrite()) {
            pos = editor.getCursorPosition();
            if (pos.column > 0)
                editor.navigateLeft();
        }

        editor.setOverwrite(true);
        editor.keyBinding.$data.buffer = "";
        editor.keyBinding.$data.state = "start";
        this.onVisualMode = false;
        this.onVisualLineMode = false;
        editor._emit("changeStatus");
        if (editor.commands.recording) {
            editor.commands.toggleRecording(editor);
            return editor.commands.macro;
        }
        else {
            return [];
        }
    },
    visualMode: function(editor, lineMode) {
        if (
            (this.onVisualLineMode && lineMode)
            || (this.onVisualMode && !lineMode)
        ) {
            this.normalMode(editor);
            return;
        }

        editor.setStyle('insert-mode');
        editor.unsetStyle('normal-mode');

        editor._emit("changeStatus");
        if (lineMode) {
            this.onVisualLineMode = true;
        } else {
            this.onVisualMode = true;
            this.onVisualLineMode = false;
        }
    },
    getRightNthChar: function(editor, cursor, ch, n) {
        var line = editor.getSession().getLine(cursor.row);
        var matches = line.substr(cursor.column + 1).split(ch);

        return n < matches.length ? matches.slice(0, n).join(ch).length : null;
    },
    getLeftNthChar: function(editor, cursor, ch, n) {
        var line = editor.getSession().getLine(cursor.row);
        var matches = line.substr(0, cursor.column).split(ch);

        return n < matches.length ? matches.slice(-1 * n).join(ch).length : null;
    },
    toRealChar: function(ch) {
        if (ch.length === 1)
            return ch;

        if (/^shift-./.test(ch))
            return ch[ch.length - 1].toUpperCase();
        else
            return "";
    },
    copyLine: function(editor) {
        var pos = editor.getCursorPosition();
        editor.selection.clearSelection();
        editor.moveCursorTo(pos.row, pos.column);
        editor.selection.selectLine();
        registers._default.isLine = true;
        registers._default.text = editor.getCopyText().replace(/\n$/, "");
        editor.selection.clearSelection();
        editor.moveCursorTo(pos.row, pos.column);
    }
};
});

ace.define('ace/keyboard/vim/registers', ['require', 'exports', 'module' ], function(require, exports, module) {

"never use strict";

module.exports = {
    _default: {
        text: "",
        isLine: false
    }
};

});


ace.define('ace/keyboard/vim/maps/motions', ['require', 'exports', 'module' , 'ace/keyboard/vim/maps/util', 'ace/search', 'ace/range'], function(require, exports, module) {


var util = require("./util");

var keepScrollPosition = function(editor, fn) {
    var scrollTopRow = editor.renderer.getScrollTopRow();
    var initialRow = editor.getCursorPosition().row;
    var diff = initialRow - scrollTopRow;
    fn && fn.call(editor);
    editor.renderer.scrollToRow(editor.getCursorPosition().row - diff);
};

function Motion(m) {
    if (typeof m == "function") {
        var getPos = m;
        m = this;
    } else {
        var getPos = m.getPos;
    }
    m.nav = function(editor, range, count, param) {
        var a = getPos(editor, range, count, param, false);
        if (!a)
            return;
        editor.clearSelection();
        editor.moveCursorTo(a.row, a.column);
    };
    m.sel = function(editor, range, count, param) {
        var a = getPos(editor, range, count, param, true);
        if (!a)
            return;
        editor.selection.selectTo(a.row, a.column);
    };
    return m;
}

var nonWordRe = /[\s.\/\\()\"'-:,.;<>~!@#$%^&*|+=\[\]{}`~?]/;
var wordSeparatorRe = /[.\/\\()\"'-:,.;<>~!@#$%^&*|+=\[\]{}`~?]/;
var whiteRe = /\s/;
var StringStream = function(editor, cursor) {
    var sel = editor.selection;
    this.range = sel.getRange();
    cursor = cursor || sel.selectionLead;
    this.row = cursor.row;
    this.col = cursor.column;
    var line = editor.session.getLine(this.row);
    var maxRow = editor.session.getLength();
    this.ch = line[this.col] || '\n';
    this.skippedLines = 0;

    this.next = function() {
        this.ch = line[++this.col] || this.handleNewLine(1);
        return this.ch;
    };
    this.prev = function() {
        this.ch = line[--this.col] || this.handleNewLine(-1);
        return this.ch;
    };
    this.peek = function(dir) {
        var ch = line[this.col + dir];
        if (ch)
            return ch;
        if (dir == -1)
            return '\n';
        if (this.col == line.length - 1)
            return '\n';
        return editor.session.getLine(this.row + 1)[0] || '\n';
    };

    this.handleNewLine = function(dir) {
        if (dir == 1){
            if (this.col == line.length)
                return '\n';
            if (this.row == maxRow - 1)
                return '';
            this.col = 0;
            this.row ++;
            line = editor.session.getLine(this.row);
            this.skippedLines++;
            return line[0] || '\n';
        }
        if (dir == -1) {
            if (this.row === 0)
                return '';
            this.row --;
            line = editor.session.getLine(this.row);
            this.col = line.length;
            this.skippedLines--;
            return '\n';
        }
    };
    this.debug = function() {
        console.log(line.substring(0, this.col)+'|'+this.ch+'\''+this.col+'\''+line.substr(this.col+1));
    };
};

var Search = require("../../../search").Search;
var search = new Search();

function find(editor, needle, dir) {
    search.$options.needle = needle;
    search.$options.backwards = dir == -1;
    return search.find(editor.session);
}

var Range = require("../../../range").Range;

var LAST_SEARCH_MOTION = {};

module.exports = {
    "w": new Motion(function(editor) {
        var str = new StringStream(editor);

        if (str.ch && wordSeparatorRe.test(str.ch)) {
            while (str.ch && wordSeparatorRe.test(str.ch))
                str.next();
        } else {
            while (str.ch && !nonWordRe.test(str.ch))
                str.next();
        }
        while (str.ch && whiteRe.test(str.ch) && str.skippedLines < 2)
            str.next();

        str.skippedLines == 2 && str.prev();
        return {column: str.col, row: str.row};
    }),
    "W": new Motion(function(editor) {
        var str = new StringStream(editor);
        while(str.ch && !(whiteRe.test(str.ch) && !whiteRe.test(str.peek(1))) && str.skippedLines < 2)
            str.next();
        if (str.skippedLines == 2)
            str.prev();
        else
            str.next();

        return {column: str.col, row: str.row};
    }),
    "b": new Motion(function(editor) {
        var str = new StringStream(editor);

        str.prev();
        while (str.ch && whiteRe.test(str.ch) && str.skippedLines > -2)
            str.prev();

        if (str.ch && wordSeparatorRe.test(str.ch)) {
            while (str.ch && wordSeparatorRe.test(str.ch))
                str.prev();
        } else {
            while (str.ch && !nonWordRe.test(str.ch))
                str.prev();
        }
        str.ch && str.next();
        return {column: str.col, row: str.row};
    }),
    "B": new Motion(function(editor) {
        var str = new StringStream(editor);
        str.prev();
        while(str.ch && !(!whiteRe.test(str.ch) && whiteRe.test(str.peek(-1))) && str.skippedLines > -2)
            str.prev();

        if (str.skippedLines == -2)
            str.next();

        return {column: str.col, row: str.row};
    }),
    "e": new Motion(function(editor) {
        var str = new StringStream(editor);

        str.next();
        while (str.ch && whiteRe.test(str.ch))
            str.next();

        if (str.ch && wordSeparatorRe.test(str.ch)) {
            while (str.ch && wordSeparatorRe.test(str.ch))
                str.next();
        } else {
            while (str.ch && !nonWordRe.test(str.ch))
                str.next();
        }
        str.ch && str.prev();
        return {column: str.col, row: str.row};
    }),
    "E": new Motion(function(editor) {
        var str = new StringStream(editor);
        str.next();
        while(str.ch && !(!whiteRe.test(str.ch) && whiteRe.test(str.peek(1))))
            str.next();

        return {column: str.col, row: str.row};
    }),

    "l": {
        nav: function(editor) {
            var pos = editor.getCursorPosition();
            var col = pos.column;
            var lineLen = editor.session.getLine(pos.row).length;
            if (lineLen && col !== lineLen)
                editor.navigateRight();
        },
        sel: function(editor) {
            var pos = editor.getCursorPosition();
            var col = pos.column;
            var lineLen = editor.session.getLine(pos.row).length;
            if (lineLen && col !== lineLen) //In selection mode you can select the newline
                editor.selection.selectRight();
        }
    },
    "h": {
        nav: function(editor) {
            var pos = editor.getCursorPosition();
            if (pos.column > 0)
                editor.navigateLeft();
        },
        sel: function(editor) {
            var pos = editor.getCursorPosition();
            if (pos.column > 0)
                editor.selection.selectLeft();
        }
    },
    "H": {
        nav: function(editor) {
            var row = editor.renderer.getScrollTopRow();
            editor.moveCursorTo(row);
        },
        sel: function(editor) {
            var row = editor.renderer.getScrollTopRow();
            editor.selection.selectTo(row);
        }
    },
    "M": {
        nav: function(editor) {
            var topRow = editor.renderer.getScrollTopRow();
            var bottomRow = editor.renderer.getScrollBottomRow();
            var row = topRow + ((bottomRow - topRow) / 2);
            editor.moveCursorTo(row);
        },
        sel: function(editor) {
            var topRow = editor.renderer.getScrollTopRow();
            var bottomRow = editor.renderer.getScrollBottomRow();
            var row = topRow + ((bottomRow - topRow) / 2);
            editor.selection.selectTo(row);
        }
    },
    "L": {
        nav: function(editor) {
            var row = editor.renderer.getScrollBottomRow();
            editor.moveCursorTo(row);
        },
        sel: function(editor) {
            var row = editor.renderer.getScrollBottomRow();
            editor.selection.selectTo(row);
        }
    },
    "k": {
        nav: function(editor) {
            editor.navigateUp();
        },
        sel: function(editor) {
            editor.selection.selectUp();
        }
    },
    "j": {
        nav: function(editor) {
            editor.navigateDown();
        },
        sel: function(editor) {
            editor.selection.selectDown();
        }
    },

    "i": {
        param: true,
        sel: function(editor, range, count, param) {
            switch (param) {
                case "w":
                    editor.selection.selectWord();
                    break;
                case "W":
                    editor.selection.selectAWord();
                    break;
                case "(":
                case "{":
                case "[":
                    var cursor = editor.getCursorPosition();
                    var end = editor.session.$findClosingBracket(param, cursor, /paren/);
                    if (!end)
                        return;
                    var start = editor.session.$findOpeningBracket(editor.session.$brackets[param], cursor, /paren/);
                    if (!start)
                        return;
                    start.column ++;
                    editor.selection.setSelectionRange(Range.fromPoints(start, end));
                    break;
                case "'":
                case '"':
                case "/":
                    var end = find(editor, param, 1);
                    if (!end)
                        return;
                    var start = find(editor, param, -1);
                    if (!start)
                        return;
                    editor.selection.setSelectionRange(Range.fromPoints(start.end, end.start));
                    break;
            }
        }
    },
    "a": {
        param: true,
        sel: function(editor, range, count, param) {
            switch (param) {
                case "w":
                    editor.selection.selectAWord();
                    break;
                case "W":
                    editor.selection.selectAWord();
                    break;
                case "(":
                case "{":
                case "[":
                    var cursor = editor.getCursorPosition();
                    var end = editor.session.$findClosingBracket(param, cursor, /paren/);
                    if (!end)
                        return;
                    var start = editor.session.$findOpeningBracket(editor.session.$brackets[param], cursor, /paren/);
                    if (!start)
                        return;
                    end.column ++;
                    editor.selection.setSelectionRange(Range.fromPoints(start, end));
                    break;
                case "'":
                case "\"":
                case "/":
                    var end = find(editor, param, 1);
                    if (!end)
                        return;
                    var start = find(editor, param, -1);
                    if (!start)
                        return;
                    end.column ++;
                    editor.selection.setSelectionRange(Range.fromPoints(start.start, end.end));
                    break;
            }
        }
    },

    "f": new Motion({
        param: true,
        handlesCount: true,
        getPos: function(editor, range, count, param, isSel, isRepeat) {
            if (!isRepeat)
                LAST_SEARCH_MOTION = {ch: "f", param: param};
            var cursor = editor.getCursorPosition();
            var column = util.getRightNthChar(editor, cursor, param, count || 1);

            if (typeof column === "number") {
                cursor.column += column + (isSel ? 2 : 1);
                return cursor;
            }
        }
    }),
    "F": new Motion({
        param: true,
        handlesCount: true,
        getPos: function(editor, range, count, param, isSel, isRepeat) {
            if (!isRepeat)
                LAST_SEARCH_MOTION = {ch: "F", param: param};
            var cursor = editor.getCursorPosition();
            var column = util.getLeftNthChar(editor, cursor, param, count || 1);

            if (typeof column === "number") {
                cursor.column -= column + 1;
                return cursor;
            }
        }
    }),
    "t": new Motion({
        param: true,
        handlesCount: true,
        getPos: function(editor, range, count, param, isSel, isRepeat) {
            if (!isRepeat)
                LAST_SEARCH_MOTION = {ch: "t", param: param};
            var cursor = editor.getCursorPosition();
            var column = util.getRightNthChar(editor, cursor, param, count || 1);

            if (isRepeat && column == 0 && !(count > 1))
                var column = util.getRightNthChar(editor, cursor, param, 2);
                
            if (typeof column === "number") {
                cursor.column += column + (isSel ? 1 : 0);
                return cursor;
            }
        }
    }),
    "T": new Motion({
        param: true,
        handlesCount: true,
        getPos: function(editor, range, count, param, isSel, isRepeat) {
            if (!isRepeat)
                LAST_SEARCH_MOTION = {ch: "T", param: param};
            var cursor = editor.getCursorPosition();
            var column = util.getLeftNthChar(editor, cursor, param, count || 1);

            if (isRepeat && column == 0 && !(count > 1))
                var column = util.getLeftNthChar(editor, cursor, param, 2);
            
            if (typeof column === "number") {
                cursor.column -= column;
                return cursor;
            }
        }
    }),
    ";": new Motion({
        handlesCount: true,
        getPos: function(editor, range, count, param, isSel) {
            var ch = LAST_SEARCH_MOTION.ch;
            if (!ch)
                return;
            return module.exports[ch].getPos(
                editor, range, count, LAST_SEARCH_MOTION.param, isSel, true
            );
        }
    }),
    ",": new Motion({
        handlesCount: true,
        getPos: function(editor, range, count, param, isSel) {
            var ch = LAST_SEARCH_MOTION.ch;
            if (!ch)
                return;
            var up = ch.toUpperCase();
            ch = ch === up ? ch.toLowerCase() : up;
            
            return module.exports[ch].getPos(
                editor, range, count, LAST_SEARCH_MOTION.param, isSel, true
            );
        }
    }),

    "^": {
        nav: function(editor) {
            editor.navigateLineStart();
        },
        sel: function(editor) {
            editor.selection.selectLineStart();
        }
    },
    "$": {
        nav: function(editor) {
            editor.navigateLineEnd();
        },
        sel: function(editor) {
            editor.selection.selectLineEnd();
        }
    },
    "0": new Motion(function(ed) {
        return {row: ed.selection.lead.row, column: 0};
    }),
    "G": {
        nav: function(editor, range, count, param) {
            if (!count && count !== 0) { // Stupid JS
                count = editor.session.getLength();
            }
            editor.gotoLine(count);
        },
        sel: function(editor, range, count, param) {
            if (!count && count !== 0) { // Stupid JS
                count = editor.session.getLength();
            }
            editor.selection.selectTo(count, 0);
        }
    },
    "g": {
        param: true,
        nav: function(editor, range, count, param) {
            switch(param) {
                case "m":
                    console.log("Middle line");
                    break;
                case "e":
                    console.log("End of prev word");
                    break;
                case "g":
                    editor.gotoLine(count || 0);
                case "u":
                    editor.gotoLine(count || 0);
                case "U":
                    editor.gotoLine(count || 0);
            }
        },
        sel: function(editor, range, count, param) {
            switch(param) {
                case "m":
                    console.log("Middle line");
                    break;
                case "e":
                    console.log("End of prev word");
                    break;
                case "g":
                    editor.selection.selectTo(count || 0, 0);
            }
        }
    },
    "o": {
        nav: function(editor, range, count, param) {
            count = count || 1;
            var content = "";
            while (0 < count--)
                content += "\n";

            if (content.length) {
                editor.navigateLineEnd()
                editor.insert(content);
                util.insertMode(editor);
            }
        }
    },
    "O": {
        nav: function(editor, range, count, param) {
            var row = editor.getCursorPosition().row;
            count = count || 1;
            var content = "";
            while (0 < count--)
                content += "\n";

            if (content.length) {
                if(row > 0) {
                    editor.navigateUp();
                    editor.navigateLineEnd()
                    editor.insert(content);
                } else {
                    editor.session.insert({row: 0, column: 0}, content);
                    editor.navigateUp();
                }
                util.insertMode(editor);
            }
        }
    },
    "%": new Motion(function(editor){
        var brRe = /[\[\]{}()]/g;
        var cursor = editor.getCursorPosition();
        var ch = editor.session.getLine(cursor.row)[cursor.column];
        if (!brRe.test(ch)) {
            var range = find(editor, brRe);
            if (!range)
                return;
            cursor = range.start;
        }
        var match = editor.session.findMatchingBracket({
            row: cursor.row,
            column: cursor.column + 1
        });

        return match;
    }),
    "{": new Motion(function(ed) {
        var session = ed.session;
        var row = session.selection.lead.row;
        while(row > 0 && !/\S/.test(session.getLine(row)))
            row--;
        while(/\S/.test(session.getLine(row)))
            row--;
        return {column: 0, row: row};
    }),
    "}": new Motion(function(ed) {
        var session = ed.session;
        var l = session.getLength();
        var row = session.selection.lead.row;
        while(row < l && !/\S/.test(session.getLine(row)))
            row++;
        while(/\S/.test(session.getLine(row)))
            row++;
        return {column: 0, row: row};
    }),
    "ctrl-d": {
        nav: function(editor, range, count, param) {
            editor.selection.clearSelection();
            keepScrollPosition(editor, editor.gotoPageDown);
        },
        sel: function(editor, range, count, param) {
            keepScrollPosition(editor, editor.selectPageDown);
        }
    },
    "ctrl-u": {
        nav: function(editor, range, count, param) {
            editor.selection.clearSelection();
            keepScrollPosition(editor, editor.gotoPageUp);
        },
        sel: function(editor, range, count, param) {
            keepScrollPosition(editor, editor.selectPageUp);
        }
    },
    "`": new Motion({
        param: true,
        handlesCount: true,
        getPos: function(editor, range, count, param, isSel) {
            var s = editor.session;
            var marker = s.vimMarkers && s.vimMarkers[param];
            if (marker) {
                return marker.getPosition();
            }
        }
    }),
    "'": new Motion({
        param: true,
        handlesCount: true,
        getPos: function(editor, range, count, param, isSel) {
            var s = editor.session;
            var marker = s.vimMarkers && s.vimMarkers[param];
            if (marker) {
                var pos = marker.getPosition();
                var line = editor.session.getLine(pos.row);                
                pos.column = line.search(/\S/);
                if (pos.column == -1)
                    pos.column = line.length;
                return pos;
            }
        }
    })
};

module.exports.backspace = module.exports.left = module.exports.h;
module.exports.space = module.exports['return'] = module.exports.right = module.exports.l;
module.exports.up = module.exports.k;
module.exports.down = module.exports.j;
module.exports.pagedown = module.exports["ctrl-d"];
module.exports.pageup = module.exports["ctrl-u"];

});
 
ace.define('ace/keyboard/vim/maps/operators', ['require', 'exports', 'module' , 'ace/keyboard/vim/maps/util', 'ace/keyboard/vim/registers'], function(require, exports, module) {



var util = require("./util");
var registers = require("../registers");

module.exports = {
    "d": {
        selFn: function(editor, range, count, param) {
            registers._default.text = editor.getCopyText();
            registers._default.isLine = util.onVisualLineMode;
            if(util.onVisualLineMode)
                editor.removeLines();
            else
                editor.session.remove(range);
            util.normalMode(editor);
        },
        fn: function(editor, range, count, param) {
            count = count || 1;
            switch (param) {
                case "d":
                    registers._default.text = "";
                    registers._default.isLine = true;
                    for (var i = 0; i < count; i++) {
                        editor.selection.selectLine();
                        registers._default.text += editor.getCopyText();
                        var selRange = editor.getSelectionRange();
                        if (!selRange.isMultiLine()) {
                            var row = selRange.start.row - 1;
                            var col = editor.session.getLine(row).length
                            selRange.setStart(row, col);
                            editor.session.remove(selRange);
                            editor.selection.clearSelection();
                            break;
                        }
                        editor.session.remove(selRange);
                        editor.selection.clearSelection();
                    }
                    registers._default.text = registers._default.text.replace(/\n$/, "");
                    break;
                default:
                    if (range) {
                        editor.selection.setSelectionRange(range);
                        registers._default.text = editor.getCopyText();
                        registers._default.isLine = false;
                        editor.session.remove(range);
                        editor.selection.clearSelection();
                    }
            }
        }
    },
    "c": {
        selFn: function(editor, range, count, param) {
            editor.session.remove(range);
            util.insertMode(editor);
        },
        fn: function(editor, range, count, param) {
            count = count || 1;
            switch (param) {
                case "c":
                    for (var i = 0; i < count; i++) {
                        editor.removeLines();
                        util.insertMode(editor);
                    }

                    break;
                default:
                    if (range) {
                        editor.session.remove(range);
                        util.insertMode(editor);
                    }
            }
        }
    },
    "y": {
        selFn: function(editor, range, count, param) {
            registers._default.text = editor.getCopyText();
            registers._default.isLine = util.onVisualLineMode;
            editor.selection.clearSelection();
            util.normalMode(editor);
        },
        fn: function(editor, range, count, param) {
            count = count || 1;
            switch (param) {
                case "y":
                    var pos = editor.getCursorPosition();
                    editor.selection.selectLine();
                    for (var i = 0; i < count - 1; i++) {
                        editor.selection.moveCursorDown();
                    }
                    registers._default.text = editor.getCopyText().replace(/\n$/, "");
                    editor.selection.clearSelection();
                    registers._default.isLine = true;
                    editor.moveCursorToPosition(pos);
                    break;
                default:
                    if (range) {
                        var pos = editor.getCursorPosition();
                        editor.selection.setSelectionRange(range);
                        registers._default.text = editor.getCopyText();
                        registers._default.isLine = false;
                        editor.selection.clearSelection();
                        editor.moveCursorTo(pos.row, pos.column);
                    }
            }
        }
    },
    ">": {
        selFn: function(editor, range, count, param) {
            count = count || 1;
            for (var i = 0; i < count; i++) {
                editor.indent();
            }
            util.normalMode(editor);
        },
        fn: function(editor, range, count, param) {
            count = parseInt(count || 1, 10);
            switch (param) {
                case ">":
                    var pos = editor.getCursorPosition();
                    editor.selection.selectLine();
                    for (var i = 0; i < count - 1; i++) {
                        editor.selection.moveCursorDown();
                    }
                    editor.indent();
                    editor.selection.clearSelection();
                    editor.moveCursorToPosition(pos);
                    editor.navigateLineEnd();
                    editor.navigateLineStart();
                    break;
            }
        }
    },
    "<": {
        selFn: function(editor, range, count, param) {
            count = count || 1;
            for (var i = 0; i < count; i++) {
                editor.blockOutdent();
            }
            util.normalMode(editor);
        },
        fn: function(editor, range, count, param) {
            count = count || 1;
            switch (param) {
                case "<":
                    var pos = editor.getCursorPosition();
                    editor.selection.selectLine();
                    for (var i = 0; i < count - 1; i++) {
                        editor.selection.moveCursorDown();
                    }
                    editor.blockOutdent();
                    editor.selection.clearSelection();
                    editor.moveCursorToPosition(pos);
                    editor.navigateLineEnd();
                    editor.navigateLineStart();
                    break;
            }
        }
    }
};
});
 
"use strict"

ace.define('ace/keyboard/vim/maps/aliases', ['require', 'exports', 'module' ], function(require, exports, module) {
module.exports = {
    "x": {
        operator: {
            ch: "d",
            count: 1
        },
        motion: {
            ch: "l",
            count: 1
        }
    },
    "X": {
        operator: {
            ch: "d",
            count: 1
        },
        motion: {
            ch: "h",
            count: 1
        }
    },
    "D": {
        operator: {
            ch: "d",
            count: 1
        },
        motion: {
            ch: "$",
            count: 1
        }
    },
    "C": {
        operator: {
            ch: "c",
            count: 1
        },
        motion: {
            ch: "$",
            count: 1
        }
    },
    "s": {
        operator: {
            ch: "c",
            count: 1
        },
        motion: {
            ch: "l",
            count: 1
        }
    },
    "S": {
        operator: {
            ch: "c",
            count: 1
        },
        param: "c"
    }
};
});

