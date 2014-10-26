// ** I18N

// Calendar EN language
// Author: Idan Sofer, <idan@idanso.dyndns.org>
// Encoding: UTF-8
// Distributed under the same terms as the calendar itself.

// For translators: please use UTF-8 if possible.  We strongly believe that
// Unicode is the answer to a real internationalized world.  Also please
// include your contact information in the header, as can be seen above.

// full day names
Calendar._DN = new Array
("ראשון",
 "שני",
 "שלישי",
 "רביעי",
 "חמישי",
 "שישי",
 "שבת",
 "ראשון");

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
("א",
 "ב",
 "ג",
 "ד",
 "ה",
 "ו",
 "ש",
 "א");

// full month names
Calendar._MN = new Array
("ינואר",
 "פברואר",
 "מרץ",
 "אפריל",
 "מאי",
 "יוני",
 "יולי",
 "אוגוסט",
 "ספטמבר",
 "אוקטובר",
 "נובמבר",
 "דצמבר");

// short month names
Calendar._SMN = new Array
("ינא",
 "פבר",
 "מרץ",
 "אפר",
 "מאי",
 "יונ",
 "יול",
 "אוג",
 "ספט",
 "אוק",
 "נוב",
 "דצמ");

// tooltips
Calendar._TT = {};
Calendar._TT["INFO"] = "אודות השנתון";

Calendar._TT["ABOUT"] =
"בחרן תאריך/שעה DHTML\n" +
"(c) dynarch.com 2002-2005 / Author: Mihai Bazon\n" + // don't translate this this ;-)
"הגירסא האחרונה זמינה ב: http://www.dynarch.com/projects/calendar/\n" +
"מופץ תחת זיכיון ה GNU LGPL.  עיין ב http://gnu.org/licenses/lgpl.html לפרטים נוספים." +
"\n\n" +
בחירת תאריך:\n" +
"- השתמש בכפתורים \xab, \xbb לבחירת שנה\n" +
"- השתמש בכפתורים " + String.fromCharCode(0x2039) + ", " + String.fromCharCode(0x203a) + " לבחירת חודש\n" +
"- החזק העכבר לחוץ מעל הכפתורים המוזכרים לעיל לבחירה מהירה יותר.";
Calendar._TT["ABOUT_TIME"] = "\n\n" +
"בחירת זמן:\n" +
"- לחץ על כל אחד מחלקי הזמן כדי להוסיף\n" +
"- או shift בשילוב עם לחיצה כדי להחסיר\n" +
"- או לחץ וגרור לפעולה מהירה יותר.";

Calendar._TT["PREV_YEAR"] = "שנה קודמת - החזק לקבלת תפריט";
Calendar._TT["PREV_MONTH"] = "חודש קודם - החזק לקבלת תפריט";
Calendar._TT["GO_TODAY"] = "עבור להיום";
Calendar._TT["NEXT_MONTH"] = "חודש הבא - החזק לתפריט";
Calendar._TT["NEXT_YEAR"] = "שנה הבאה - החזק לתפריט";
Calendar._TT["SEL_DATE"] = "בחר תאריך";
Calendar._TT["DRAG_TO_MOVE"] = "גרור להזזה";
Calendar._TT["PART_TODAY"] = " )היום(";

// the following is to inform that "%s" is to be the first day of week
// %s will be replaced with the day name.
Calendar._TT["DAY_FIRST"] = "הצג %s קודם";

// This may be locale-dependent.  It specifies the week-end days, as an array
// of comma-separated numbers.  The numbers are from 0 to 6: 0 means Sunday, 1
// means Monday, etc.
Calendar._TT["WEEKEND"] = "6";

Calendar._TT["CLOSE"] = "סגור";
Calendar._TT["TODAY"] = "היום";
Calendar._TT["TIME_PART"] = "(שיפט-)לחץ וגרור כדי לשנות ערך";

// date formats
Calendar._TT["DEF_DATE_FORMAT"] = "%Y-%m-%d";
Calendar._TT["TT_DATE_FORMAT"] = "%a, %b %e";

Calendar._TT["WK"] = "wk";
Calendar._TT["TIME"] = "שעה::";
