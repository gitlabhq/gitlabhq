// ** I18N

// Calendar pt-BR language
// Author: Fernando Dourado, <fernando.dourado@ig.com.br>
// Encoding: any
// Distributed under the same terms as the calendar itself.

// For translators: please use UTF-8 if possible.  We strongly believe that
// Unicode is the answer to a real internationalized world.  Also please
// include your contact information in the header, as can be seen above.

// full day names
Calendar._DN = new Array
("Domingo",
 "Segunda",
 "Terça",
 "Quarta",
 "Quinta",
 "Sexta",
 "Sabádo",
 "Domingo");

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
// [No changes using default values]

// full month names
Calendar._MN = new Array
("Janeiro",
 "Fevereiro",
 "Março",
 "Abril",
 "Maio",
 "Junho",
 "Julho",
 "Agosto",
 "Setembro",
 "Outubro",
 "Novembro",
 "Dezembro");

// short month names
// [No changes using default values]

// tooltips
Calendar._TT = {};
Calendar._TT["INFO"] = "Sobre o calendário";

Calendar._TT["ABOUT"] =
"DHTML Date/Time Selector\n" +
"(c) dynarch.com 2002-2005 / Author: Mihai Bazon\n" + // don't translate this this ;-)
"For latest version visit: http://www.dynarch.com/projects/calendar/\n" +
"Distributed under GNU LGPL.  See http://gnu.org/licenses/lgpl.html for details." +
"\n\n" +
"Translate to portuguese Brazil (pt-BR) by Fernando Dourado (fernando.dourado@ig.com.br)\n" +
"Tradução para o português Brasil (pt-BR) por Fernando Dourado (fernando.dourado@ig.com.br)" +
"\n\n" +
"Selecionar data:\n" +
"- Use as teclas \xab, \xbb para selecionar o ano\n" +
"- Use as teclas " + String.fromCharCode(0x2039) + ", " + String.fromCharCode(0x203a) + " para selecionar o mês\n" +
"- Clique e segure com o mouse em qualquer botão para selecionar rapidamente.";

Calendar._TT["ABOUT_TIME"] = "\n\n" +
"Selecionar hora:\n" +
"- Clique em qualquer uma das partes da hora para aumentar\n" +
"- ou Shift-clique para diminuir\n" +
"- ou clique e arraste para selecionar rapidamente.";

Calendar._TT["PREV_YEAR"] = "Ano anterior (clique e segure para menu)";
Calendar._TT["PREV_MONTH"] = "Mês anterior (clique e segure para menu)";
Calendar._TT["GO_TODAY"] = "Ir para a data atual";
Calendar._TT["NEXT_MONTH"] = "Próximo mês (clique e segure para menu)";
Calendar._TT["NEXT_YEAR"] = "Próximo ano (clique e segure para menu)";
Calendar._TT["SEL_DATE"] = "Selecione uma data";
Calendar._TT["DRAG_TO_MOVE"] = "Clique e segure para mover";
Calendar._TT["PART_TODAY"] = " (hoje)";

// the following is to inform that "%s" is to be the first day of week
// %s will be replaced with the day name.
Calendar._TT["DAY_FIRST"] = "Exibir %s primeiro";

// This may be locale-dependent.  It specifies the week-end days, as an array
// of comma-separated numbers.  The numbers are from 0 to 6: 0 means Sunday, 1
// means Monday, etc.
Calendar._TT["WEEKEND"] = "0,6";

Calendar._TT["CLOSE"] = "Fechar";
Calendar._TT["TODAY"] = "Hoje";
Calendar._TT["TIME_PART"] = "(Shift-)Clique ou arraste para mudar o valor";

// date formats
Calendar._TT["DEF_DATE_FORMAT"] = "%d/%m/%Y";
Calendar._TT["TT_DATE_FORMAT"] = "%d de %B de %Y";

Calendar._TT["WK"] = "sem";
Calendar._TT["TIME"] = "Hora:";

