// ** I18N

// Calendar BG language
// Author: Mihai Bazon, <mihai_bazon@yahoo.com>
// Translator: Valentin Sheiretsky, <valio@valio.eu.org>
// Encoding: Windows-1251
// Distributed under the same terms as the calendar itself.

// For translators: please use UTF-8 if possible.  We strongly believe that
// Unicode is the answer to a real internationalized world.  Also please
// include your contact information in the header, as can be seen above.

// full day names
Calendar._DN = new Array
("Неделя",
 "Понеделник",
 "Вторник",
 "Сряда",
 "Четвъртък",
 "Петък",
 "Събота",
 "Неделя");

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
("Нед",
 "Пон",
 "Вто",
 "Сря",
 "Чет",
 "Пет",
 "Съб",
 "Нед");

// full month names
Calendar._MN = new Array
("Януари",
 "Февруари",
 "Март",
 "Април",
 "Май",
 "Юни",
 "Юли",
 "Август",
 "Септември",
 "Октомври",
 "Ноември",
 "Декември");

// short month names
Calendar._SMN = new Array
("Яну",
 "Фев",
 "Мар",
 "Апр",
 "Май",
 "Юни",
 "Юли",
 "Авг",
 "Сеп",
 "Окт",
 "Ное",
 "Дек");

// tooltips
Calendar._TT = {};
Calendar._TT["INFO"] = "Информация за календара";

Calendar._TT["ABOUT"] =
"DHTML Date/Time Selector\n" +
"(c) dynarch.com 2002-2005 / Author: Mihai Bazon\n" + // don't translate this this ;-)
"For latest version visit: http://www.dynarch.com/projects/calendar/\n" +
"Distributed under GNU LGPL.  See http://gnu.org/licenses/lgpl.html for details." +
"\n\n" +
"Date selection:\n" +
"- Use the \xab, \xbb buttons to select year\n" +
"- Use the " + String.fromCharCode(0x2039) + ", " + String.fromCharCode(0x203a) + " buttons to select month\n" +
"- Hold mouse button on any of the above buttons for faster selection.";
Calendar._TT["ABOUT_TIME"] = "\n\n" +
"Time selection:\n" +
"- Click on any of the time parts to increase it\n" +
"- or Shift-click to decrease it\n" +
"- or click and drag for faster selection.";

Calendar._TT["PREV_YEAR"] = "Предна година (задръжте за меню)";
Calendar._TT["PREV_MONTH"] = "Преден месец (задръжте за меню)";
Calendar._TT["GO_TODAY"] = "Изберете днес";
Calendar._TT["NEXT_MONTH"] = "Следващ месец (задръжте за меню)";
Calendar._TT["NEXT_YEAR"] = "Следваща година (задръжте за меню)";
Calendar._TT["SEL_DATE"] = "Изберете дата";
Calendar._TT["DRAG_TO_MOVE"] = "Преместване";
Calendar._TT["PART_TODAY"] = " (днес)";

// the following is to inform that "%s" is to be the first day of week
// %s will be replaced with the day name.
Calendar._TT["DAY_FIRST"] = "%s като първи ден";

// This may be locale-dependent.  It specifies the week-end days, as an array
// of comma-separated numbers.  The numbers are from 0 to 6: 0 means Sunday, 1
// means Monday, etc.
Calendar._TT["WEEKEND"] = "0,6";

Calendar._TT["CLOSE"] = "Затворете";
Calendar._TT["TODAY"] = "Днес";
Calendar._TT["TIME_PART"] = "(Shift-)Click или drag за да промените стойността";

// date formats
Calendar._TT["DEF_DATE_FORMAT"] = "%Y-%m-%d";
Calendar._TT["TT_DATE_FORMAT"] = "%A - %e %B %Y";

Calendar._TT["WK"] = "Седм";
Calendar._TT["TIME"] = "Час:";
