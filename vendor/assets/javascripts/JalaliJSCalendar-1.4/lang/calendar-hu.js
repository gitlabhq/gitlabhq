// ** I18N

// Calendar HU language
// Author: ???
// Modifier: KARASZI Istvan, <jscalendar@spam.raszi.hu>
// Encoding: any
// Distributed under the same terms as the calendar itself.

// For translators: please use UTF-8 if possible.  We strongly believe that
// Unicode is the answer to a real internationalized world.  Also please
// include your contact information in the header, as can be seen above.

// full day names
Calendar._DN = new Array
("Vasárnap",
 "Hétfõ",
 "Kedd",
 "Szerda",
 "Csütörtök",
 "Péntek",
 "Szombat",
 "Vasárnap");

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
("v",
 "h",
 "k",
 "sze",
 "cs",
 "p",
 "szo",
 "v");

// full month names
Calendar._MN = new Array
("január",
 "február",
 "március",
 "április",
 "május",
 "június",
 "július",
 "augusztus",
 "szeptember",
 "október",
 "november",
 "december");

// short month names
Calendar._SMN = new Array
("jan",
 "feb",
 "már",
 "ápr",
 "máj",
 "jún",
 "júl",
 "aug",
 "sze",
 "okt",
 "nov",
 "dec");

// tooltips
Calendar._TT = {};
Calendar._TT["INFO"] = "A kalendáriumról";

Calendar._TT["ABOUT"] =
"DHTML dátum/idõ kiválasztó\n" +
"(c) dynarch.com 2002-2005 / Author: Mihai Bazon\n" + // don't translate this this ;-)
"a legfrissebb verzió megtalálható: http://www.dynarch.com/projects/calendar/\n" +
"GNU LGPL alatt terjesztve.  Lásd a http://gnu.org/licenses/lgpl.html oldalt a részletekhez." +
"\n\n" +
"Dátum választás:\n" +
"- használja a \xab, \xbb gombokat az év kiválasztásához\n" +
"- használja a " + String.fromCharCode(0x2039) + ", " + String.fromCharCode(0x203a) + " gombokat a hónap kiválasztásához\n" +
"- tartsa lenyomva az egérgombot a gyors választáshoz.";
Calendar._TT["ABOUT_TIME"] = "\n\n" +
"Idõ választás:\n" +
"- kattintva növelheti az idõt\n" +
"- shift-tel kattintva csökkentheti\n" +
"- lenyomva tartva és húzva gyorsabban kiválaszthatja.";

Calendar._TT["PREV_YEAR"] = "Elõzõ év (tartsa nyomva a menühöz)";
Calendar._TT["PREV_MONTH"] = "Elõzõ hónap (tartsa nyomva a menühöz)";
Calendar._TT["GO_TODAY"] = "Mai napra ugrás";
Calendar._TT["NEXT_MONTH"] = "Köv. hónap (tartsa nyomva a menühöz)";
Calendar._TT["NEXT_YEAR"] = "Köv. év (tartsa nyomva a menühöz)";
Calendar._TT["SEL_DATE"] = "Válasszon dátumot";
Calendar._TT["DRAG_TO_MOVE"] = "Húzza a mozgatáshoz";
Calendar._TT["PART_TODAY"] = " (ma)";

// the following is to inform that "%s" is to be the first day of week
// %s will be replaced with the day name.
Calendar._TT["DAY_FIRST"] = "%s legyen a hét elsõ napja";

// This may be locale-dependent.  It specifies the week-end days, as an array
// of comma-separated numbers.  The numbers are from 0 to 6: 0 means Sunday, 1
// means Monday, etc.
Calendar._TT["WEEKEND"] = "0,6";

Calendar._TT["CLOSE"] = "Bezár";
Calendar._TT["TODAY"] = "Ma";
Calendar._TT["TIME_PART"] = "(Shift-)Klikk vagy húzás az érték változtatásához";

// date formats
Calendar._TT["DEF_DATE_FORMAT"] = "%Y-%m-%d";
Calendar._TT["TT_DATE_FORMAT"] = "%b %e, %a";

Calendar._TT["WK"] = "hét";
Calendar._TT["TIME"] = "idõ:";
