/* JalaliJSCalendar - Setup Script
 * Copyright (c) 2008-2009 Ali Farhadi (http://farhadi.ir/)
 * 
 * Released under the terms of the GNU General Public License.
 * See the GPL for details (http://www.gnu.org/licenses/gpl.html).
 *
 * Based on The DHTML Calendar developed by Dynarch.com. (http://www.dynarch.com/projects/calendar/)
 * Copyright Mihai Bazon, 2002-2005 (www.bazon.net/mishoo)
 *
 *
 * This file defines helper functions for setting up the calendar.  They are
 * intended to help non-programmers get a working calendar on their site
 * quickly.  This script should not be seen as part of the calendar.  It just
 * shows you what one can do with the calendar, while in the same time
 * providing a quick and simple method for setting it up.  If you need
 * exhaustive customization of the calendar creation process feel free to
 * modify this code to suit your needs (this is recommended and much better
 * than modifying calendar.js itself).
 */

/**
 *  This function "patches" an input field (or other element) to use a calendar
 *  widget for date selection.
 *
 *  The "params" is a single object that can have the following properties:
 *
 *    prop. name      | description
 *  -------------------------------------------------------------------------------------------------
 *   inputField       | the ID of an input field to store the date
 *   displayArea      | the ID of a DIV or other element to show the date
 *   button           | ID of a button or other element that will trigger the calendar
 *   eventName        | event that will trigger the calendar, without the "on" prefix (default: "click")
 *   ifFormat         | date format that will be stored in the input field
 *   daFormat         | the date format that will be used to display the date in displayArea
 *   singleClick      | (true/false) wether the calendar is in single click mode or not (default: true)
 *   firstDay         | numeric: 0 to 6.  "0" means display Sunday first, "1" means display Monday first, etc.
 *   align            | alignment (default: "Br"); if you don't know what's this see the calendar documentation
 *   range            | array with 2 elements.  Default: [1900, 2999] -- the range of years available
 *   weekNumbers      | (true/false) if it's true (default) the calendar will display week numbers
 *   flat             | null or element ID; if not null the calendar will be a flat calendar having the parent with the given ID
 *   flatCallback     | function that receives a JS Date object and returns an URL to point the browser to (for flat calendar)
 *   disableFunc      | function that receives a JS Date object and should return true if that date has to be disabled in the calendar
 *   onSelect         | function that gets called when a date is selected.  You don't _have_ to supply this (the default is generally okay)
 *   onClose          | function that gets called when the calendar is closed.  [default]
 *   onUpdate         | function that gets called after the date is updated in the input field.  Receives a reference to the calendar.
 *   date             | the date that the calendar will be initially displayed to
 *   showsTime        | default: false; if true the calendar will include a time selector
 *   timeFormat       | the time format; can be "12" or "24", default is "12"
 *   electric         | if true (default) then given fields/date areas are updated for each move; otherwise they're updated only on close
 *   step             | configures the step of the years in drop-down boxes; default: 2
 *   position         | configures the calendar absolute position; default: null
 *   showOthers       | if "true" (but default: "false") it will show days from other months too
 *   dateType         | "gregorian" or "jalali" (default: "gregorian")
 *   ifDateType       | date type that will be stored in the input field (by default it is same as dateType)
 *   langNumbers      | if "true" it will use number characters specified in language file. 
 *   autoShowOnFocus  | if "true", popup calendars will also be shown when their input field gets focus
 *   autoFillAtStart  | if "true", inputField and displayArea will be filled on initialize.
 *
 *  None of them is required, they all have default values.  However, if you
 *  pass none of "inputField", "displayArea" or "button" you'll get a warning
 *  saying "nothing to setup".
 */
Calendar.setup = function (params) {
	function param_default(pname, def) { if (typeof params[pname] == "undefined") { params[pname] = def; } };

	param_default("inputField",      null);
	param_default("displayArea",     null);
	param_default("button",          null);
	param_default("eventName",       "click");
	param_default("ifFormat",        "%Y/%m/%d");
	param_default("daFormat",        "%Y/%m/%d");
	param_default("singleClick",     true);
	param_default("disableFunc",     null);
	param_default("dateStatusFunc",  params["disableFunc"]);	// takes precedence if both are defined
	param_default("dateText",        null);
	param_default("firstDay",        null);
	param_default("align",           "Br");
	param_default("range",           [1000, 3000]);
	param_default("weekNumbers",     true);
	param_default("flat",            null);
	param_default("flatCallback",    null);
	param_default("onSelect",        null);
	param_default("onClose",         null);
	param_default("onUpdate",        null);
	param_default("date",            null);
	param_default("showsTime",       false);
	param_default("timeFormat",      "24");
	param_default("electric",        true);
	param_default("step",            2);
	param_default("position",        null);
	param_default("showOthers",      false);
	param_default("multiple",        null);
	param_default("dateType",        "gregorian");
	param_default("ifDateType",      null);
	param_default("langNumbers",     false);
	param_default("autoShowOnFocus", false);
	param_default("autoFillAtStart", false);

	var tmp = ["inputField", "displayArea", "button"];
	for (var i in tmp) {
		if (typeof params[tmp[i]] == "string") {
			params[tmp[i]] = document.getElementById(params[tmp[i]]);
		}
	}
	if (!(params.flat || params.multiple || params.inputField || params.displayArea || params.button)) {
		alert("Calendar.setup:\n  Nothing to setup (no fields found).  Please check your code");
		return false;
	}

	if (params.autoFillAtStart) {
		if (params.inputField && !params.inputField.value)
			params.inputField.value = new Date(params.date).print(params.ifFormat, params.ifDateType || params.dateType, params.langNumbers);
		if (params.displayArea && !params.displayArea.innerHTML)
			params.displayArea.innerHTML = new Date(params.date).print(params.ifFormat, params.ifDateType || params.dateType, params.langNumbers);
	}
	
	function onSelect(cal) {
		var p = cal.params;
		var update = (cal.dateClicked || p.electric);
		if (update && p.inputField) {
			p.inputField.value = cal.date.print(cal.dateFormat, p.ifDateType || cal.dateType, cal.langNumbers);
			if (typeof p.inputField.onchange == "function")
				p.inputField.onchange();
		}
		if (update && p.displayArea)
			p.displayArea.innerHTML = cal.date.print(p.daFormat, cal.dateType, cal.langNumbers);
		if (update && typeof p.onUpdate == "function")
			p.onUpdate(cal);
		if (update && p.flat) {
			if (typeof p.flatCallback == "function")
				p.flatCallback(cal);
		}
		if (update && p.singleClick && cal.dateClicked)
			cal.callCloseHandler();
	};

	if (!params.flat) {
		var cal = new Calendar(params.firstDay,
									params.date,
									params.onSelect || onSelect,
									params.onClose || function(cal) { cal.hide(); });

	} else {
		if (typeof params.flat == "string")
			params.flat = document.getElementById(params.flat);
		if (!params.flat) {
			alert("Calendar.setup:\n  Flat specified but can't find parent.");
			return false;
		}
		var cal = new Calendar(params.firstDay, params.date, params.onSelect || onSelect);

		if (params.inputField && typeof params.inputField.value == "string" && params.inputField.value) {
			cal.parseDate(params.inputField.value, null, params.ifDateType || cal.dateType);
		}
	}
	cal.showsTime = params.showsTime;
	cal.time24 = (params.timeFormat == "24");
	cal.weekNumbers = params.weekNumbers;
	cal.dateType = params.dateType;
	cal.langNumbers = params.langNumbers;
	cal.showsOtherMonths = params.showOthers;
	cal.yearStep = params.step;
	cal.setRange(params.range[0], params.range[1]);
	cal.params = params;
	cal.setDateStatusHandler(params.dateStatusFunc);
	cal.getDateText = params.dateText;
	cal.setDateFormat(params.inputField ? params.ifFormat : params.daFormat);
	if (params.multiple) {
		cal.multiple = {};
		for (var i = params.multiple.length; --i >= 0;) {
			var d = params.multiple[i];
			var ds = d.print("%Y%m%d", cal.dateType, cal.langNumbers);
			cal.multiple[ds] = d;
		}
	}
	
	if (!params.flat) {
		var triggerEl = params.button || params.displayArea || params.inputField;
		triggerEl["on" + params.eventName] = function() {
			if (!cal.element) cal.create();
			var dateEl = params.inputField || params.displayArea;
			var dateType = params.inputField ? params.ifDateType || cal.dateType : cal.dateType;
			if (dateEl && (dateEl.value || dateEl.innerHTML)) params.date = Date.parseDate(dateEl.value || dateEl.innerHTML, cal.dateFormat, dateType);
			if (params.date) cal.setDate(params.date);
			cal.refresh();
			if (!params.position)
				cal.showAtElement(params.button || params.displayArea || params.inputField, params.align);
			else
				cal.showAt(params.position[0], params.position[1]);
			return false;
		};

		if (params.autoShowOnFocus && params.inputField) {
			params.inputField["onfocus"] = triggerEl["on" + params.eventName];
		};
	} else {
		cal.create(params.flat);
		cal.show();
	}
	return cal;
};
