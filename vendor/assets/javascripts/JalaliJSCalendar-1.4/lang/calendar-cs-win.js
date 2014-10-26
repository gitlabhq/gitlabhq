/* 
	calendar-cs-win.js
	language: Czech
	encoding: windows-1250
	author: Lubos Jerabek (xnet@seznam.cz)
	        Jan Uhlir (espinosa@centrum.cz)
*/

// ** I18N
Calendar._DN  = new Array('Nedìle','Pondìlí','Úterı','Støeda','Ètvrtek','Pátek','Sobota','Nedìle');
Calendar._SDN = new Array('Ne','Po','Út','St','Èt','Pá','So','Ne');
Calendar._MN  = new Array('Leden','Únor','Bøezen','Duben','Kvìten','Èerven','Èervenec','Srpen','Záøí','Øíjen','Listopad','Prosinec');
Calendar._SMN = new Array('Led','Úno','Bøe','Dub','Kvì','Èrv','Èvc','Srp','Záø','Øíj','Lis','Pro');

// tooltips
Calendar._TT = {};
Calendar._TT["INFO"] = "O komponentì kalendáø";
Calendar._TT["TOGGLE"] = "Zmìna prvního dne v tıdnu";
Calendar._TT["PREV_YEAR"] = "Pøedchozí rok (pøidr pro menu)";
Calendar._TT["PREV_MONTH"] = "Pøedchozí mìsíc (pøidr pro menu)";
Calendar._TT["GO_TODAY"] = "Dnešní datum";
Calendar._TT["NEXT_MONTH"] = "Další mìsíc (pøidr pro menu)";
Calendar._TT["NEXT_YEAR"] = "Další rok (pøidr pro menu)";
Calendar._TT["SEL_DATE"] = "Vyber datum";
Calendar._TT["DRAG_TO_MOVE"] = "Chy a táhni, pro pøesun";
Calendar._TT["PART_TODAY"] = " (dnes)";
Calendar._TT["MON_FIRST"] = "Uka jako první Pondìlí";
//Calendar._TT["SUN_FIRST"] = "Uka jako první Nedìli";

Calendar._TT["ABOUT"] =
"DHTML Date/Time Selector\n" +
"(c) dynarch.com 2002-2005 / Author: Mihai Bazon\n" + // don't translate this this ;-)
"For latest version visit: http://www.dynarch.com/projects/calendar/\n" +
"Distributed under GNU LGPL.  See http://gnu.org/licenses/lgpl.html for details." +
"\n\n" +
"Vıbìr datumu:\n" +
"- Use the \xab, \xbb buttons to select year\n" +
"- Pouijte tlaèítka " + String.fromCharCode(0x2039) + ", " + String.fromCharCode(0x203a) + " k vıbìru mìsíce\n" +
"- Podrte tlaèítko myši na jakémkoliv z tìch tlaèítek pro rychlejší vıbìr.";

Calendar._TT["ABOUT_TIME"] = "\n\n" +
"Vıbìr èasu:\n" +
"- Kliknìte na jakoukoliv z èástí vıbìru èasu pro zvıšení.\n" +
"- nebo Shift-click pro sníení\n" +
"- nebo kliknìte a táhnìte pro rychlejší vıbìr.";

// the following is to inform that "%s" is to be the first day of week
// %s will be replaced with the day name.
Calendar._TT["DAY_FIRST"] = "Zobraz %s první";

// This may be locale-dependent.  It specifies the week-end days, as an array
// of comma-separated numbers.  The numbers are from 0 to 6: 0 means Sunday, 1
// means Monday, etc.
Calendar._TT["WEEKEND"] = "0,6";

Calendar._TT["CLOSE"] = "Zavøít";
Calendar._TT["TODAY"] = "Dnes";
Calendar._TT["TIME_PART"] = "(Shift-)Klikni nebo táhni pro zmìnu hodnoty";

// date formats
Calendar._TT["DEF_DATE_FORMAT"] = "d.m.yy";
Calendar._TT["TT_DATE_FORMAT"] = "%a, %b %e";

Calendar._TT["WK"] = "wk";
Calendar._TT["TIME"] = "Èas:";
