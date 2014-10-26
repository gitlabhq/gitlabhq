// ** I18N

// Calendar NO language
// Author: Daniel Holmen, <daniel.holmen@ciber.no>
// Encoding: UTF-8
// Distributed under the same terms as the calendar itself.

// For translators: please use UTF-8 if possible.  We strongly believe that
// Unicode is the answer to a real internationalized world.  Also please
// include your contact information in the header, as can be seen above.

// full day names
Calendar._DN = new Array
("Søndag",
 "Mandag",
 "Tirsdag",
 "Onsdag",
 "Torsdag",
 "Fredag",
 "Lørdag",
 "Søndag");

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
("Søn",
 "Man",
 "Tir",
 "Ons",
 "Tor",
 "Fre",
 "Lør",
 "Søn");

// full month names
Calendar._MN = new Array
("Januar",
 "Februar",
 "Mars",
 "April",
 "Mai",
 "Juni",
 "Juli",
 "August",
 "September",
 "Oktober",
 "November",
 "Desember");

// short month names
Calendar._SMN = new Array
("Jan",
 "Feb",
 "Mar",
 "Apr",
 "Mai",
 "Jun",
 "Jul",
 "Aug",
 "Sep",
 "Okt",
 "Nov",
 "Des");

// tooltips
Calendar._TT = {};
Calendar._TT["INFO"] = "Om kalenderen";

Calendar._TT["ABOUT"] =
"DHTML Dato-/Tidsvelger\n" +
"(c) dynarch.com 2002-2005 / Author: Mihai Bazon\n" + // don't translate this this ;-)
"For nyeste versjon, gå til: http://www.dynarch.com/projects/calendar/\n" +
"Distribuert under GNU LGPL.  Se http://gnu.org/licenses/lgpl.html for detaljer." +
"\n\n" +
"Datovalg:\n" +
"- Bruk knappene \xab og \xbb for å velge år\n" +
"- Bruk knappene " + String.fromCharCode(0x2039) + " og " + String.fromCharCode(0x203a) + " for å velge måned\n" +
"- Hold inne musknappen eller knappene over for raskere valg.";
Calendar._TT["ABOUT_TIME"] = "\n\n" +
"Tidsvalg:\n" +
"- Klikk på en av tidsdelene for å øke den\n" +
"- eller Shift-klikk for å senke verdien\n" +
"- eller klikk-og-dra for raskere valg..";

Calendar._TT["PREV_YEAR"] = "Forrige. år (hold for meny)";
Calendar._TT["PREV_MONTH"] = "Forrige. måned (hold for meny)";
Calendar._TT["GO_TODAY"] = "Gå til idag";
Calendar._TT["NEXT_MONTH"] = "Neste måned (hold for meny)";
Calendar._TT["NEXT_YEAR"] = "Neste år (hold for meny)";
Calendar._TT["SEL_DATE"] = "Velg dato";
Calendar._TT["DRAG_TO_MOVE"] = "Dra for å flytte";
Calendar._TT["PART_TODAY"] = " (idag)";
Calendar._TT["MON_FIRST"] = "Vis mandag først";
Calendar._TT["SUN_FIRST"] = "Vis søndag først";
Calendar._TT["CLOSE"] = "Lukk";
Calendar._TT["TODAY"] = "Idag";
Calendar._TT["TIME_PART"] = "(Shift-)Klikk eller dra for å endre verdi";

// date formats
Calendar._TT["DEF_DATE_FORMAT"] = "%d.%m.%Y";
Calendar._TT["TT_DATE_FORMAT"] = "%a, %b %e";

Calendar._TT["WK"] = "uke";