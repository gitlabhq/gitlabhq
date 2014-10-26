// ** I18N

// Calendar DE language
// Author: Jack (tR), <jack@jtr.de>
// Encoding: any
// Distributed under the same terms as the calendar itself.

// For translators: please use UTF-8 if possible.  We strongly believe that
// Unicode is the answer to a real internationalized world.  Also please
// include your contact information in the header, as can be seen above.

// full day names
Calendar._DN = new Array
("Sonntag",
 "Montag",
 "Dienstag",
 "Mittwoch",
 "Donnerstag",
 "Freitag",
 "Samstag",
 "Sonntag");

// Please note that the following array of short day names (and the same goes
// for short month names, _SMN) isn't absolutely necessary.  We give it here
// for exemplification on how one can customize the short day names, but if
// they are simply the first N letters of the full name you can simply say:
//
//   Calendar._SDN_len = N; // short day name length
//   Calendar._SMN_len = N; // short month name length
//
// If N = 3 then this is not needed either since we assume a value of 3 if not
// present, to be compatible with translation files that were written before
// this feature.

// short day names
Calendar._SDN = new Array
("So",
 "Mo",
 "Di",
 "Mi",
 "Do",
 "Fr",
 "Sa",
 "So");

// full month names
Calendar._MN = new Array
("Januar",
 "Februar",
 "M\u00e4rz",
 "April",
 "Mai",
 "Juni",
 "Juli",
 "August",
 "September",
 "Oktober",
 "November",
 "Dezember");

// short month names
Calendar._SMN = new Array
("Jan",
 "Feb",
 "M\u00e4r",
 "Apr",
 "May",
 "Jun",
 "Jul",
 "Aug",
 "Sep",
 "Okt",
 "Nov",
 "Dez");

// tooltips
Calendar._TT = {};
Calendar._TT["INFO"] = "\u00DCber dieses Kalendarmodul";

Calendar._TT["ABOUT"] =
"DHTML Date/Time Selector\n" +
"(c) dynarch.com 2002-2005 / Author: Mihai Bazon\n" + // don't translate this ;-)
"For latest version visit: http://www.dynarch.com/projects/calendar/\n" +
"Distributed under GNU LGPL.  See http://gnu.org/licenses/lgpl.html for details." +
"\n\n" +
"Datum ausw\u00e4hlen:\n" +
"- Benutzen Sie die \xab, \xbb Buttons um das Jahr zu w\u00e4hlen\n" +
"- Benutzen Sie die " + String.fromCharCode(0x2039) + ", " + String.fromCharCode(0x203a) + " Buttons um den Monat zu w\u00e4hlen\n" +
"- F\u00fcr eine Schnellauswahl halten Sie die Maustaste \u00fcber diesen Buttons fest.";
Calendar._TT["ABOUT_TIME"] = "\n\n" +
"Zeit ausw\u00e4hlen:\n" +
"- Klicken Sie auf die Teile der Uhrzeit, um diese zu erh\u00F6hen\n" +
"- oder klicken Sie mit festgehaltener Shift-Taste um diese zu verringern\n" +
"- oder klicken und festhalten f\u00fcr Schnellauswahl.";

Calendar._TT["TOGGLE"] = "Ersten Tag der Woche w\u00e4hlen";
Calendar._TT["PREV_YEAR"] = "Voriges Jahr (Festhalten f\u00fcr Schnellauswahl)";
Calendar._TT["PREV_MONTH"] = "Voriger Monat (Festhalten f\u00fcr Schnellauswahl)";
Calendar._TT["GO_TODAY"] = "Heute ausw\u00e4hlen";
Calendar._TT["NEXT_MONTH"] = "N\u00e4chst. Monat (Festhalten f\u00fcr Schnellauswahl)";
Calendar._TT["NEXT_YEAR"] = "N\u00e4chst. Jahr (Festhalten f\u00fcr Schnellauswahl)";
Calendar._TT["SEL_DATE"] = "Datum ausw\u00e4hlen";
Calendar._TT["DRAG_TO_MOVE"] = "Zum Bewegen festhalten";
Calendar._TT["PART_TODAY"] = " (Heute)";

// the following is to inform that "%s" is to be the first day of week
// %s will be replaced with the day name.
Calendar._TT["DAY_FIRST"] = "Woche beginnt mit %s ";

// This may be locale-dependent.  It specifies the week-end days, as an array
// of comma-separated numbers.  The numbers are from 0 to 6: 0 means Sunday, 1
// means Monday, etc.
Calendar._TT["WEEKEND"] = "0,6";

Calendar._TT["CLOSE"] = "Schlie\u00dfen";
Calendar._TT["TODAY"] = "Heute";
Calendar._TT["TIME_PART"] = "(Shift-)Klick oder Festhalten und Ziehen um den Wert zu \u00e4ndern";

// date formats
Calendar._TT["DEF_DATE_FORMAT"] = "%d.%m.%Y";
Calendar._TT["TT_DATE_FORMAT"] = "%a, %b %e";

Calendar._TT["WK"] = "wk";
Calendar._TT["TIME"] = "Zeit:";
