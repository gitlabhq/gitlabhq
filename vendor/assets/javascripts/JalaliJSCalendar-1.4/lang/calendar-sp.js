// ** I18N

// Calendar SP language
// Author: Rafael Velasco <rvu_at_idecnet_dot_com>
// Encoding: any
// Distributed under the same terms as the calendar itself.

// For translators: please use UTF-8 if possible.  We strongly believe that
// Unicode is the answer to a real internationalized world.  Also please
// include your contact information in the header, as can be seen above.

// full day names
Calendar._DN = new Array
("Domingo",
 "Lunes",
 "Martes",
 "Miercoles",
 "Jueves",
 "Viernes",
 "Sabado",
 "Domingo");

Calendar._SDN = new Array
("Dom",
 "Lun",
 "Mar",
 "Mie",
 "Jue",
 "Vie",
 "Sab",
 "Dom");

// full month names
Calendar._MN = new Array
("Enero",
 "Febrero",
 "Marzo",
 "Abril",
 "Mayo",
 "Junio",
 "Julio",
 "Agosto",
 "Septiembre",
 "Octubre",
 "Noviembre",
 "Diciembre");

// short month names
Calendar._SMN = new Array
("Ene",
 "Feb",
 "Mar",
 "Abr",
 "May",
 "Jun",
 "Jul",
 "Ago",
 "Sep",
 "Oct",
 "Nov",
 "Dic");

// tooltips
Calendar._TT = {};
Calendar._TT["INFO"] = "Información del Calendario";

Calendar._TT["ABOUT"] =
"DHTML Date/Time Selector\n" +
"(c) dynarch.com 2002-2005 / Author: Mihai Bazon\n" + // don't translate this this ;-)
"Nuevas versiones en: http://www.dynarch.com/projects/calendar/\n" +
"Distribuida bajo licencia GNU LGPL.  Para detalles vea http://gnu.org/licenses/lgpl.html ." +
"\n\n" +
"Selección de Fechas:\n" +
"- Use  \xab, \xbb para seleccionar el año\n" +
"- Use " + String.fromCharCode(0x2039) + ", " + String.fromCharCode(0x203a) + " para seleccionar el mes\n" +
"- Mantenga presionado el botón del ratón en cualquiera de las opciones superiores para un acceso rapido .";
Calendar._TT["ABOUT_TIME"] = "\n\n" +
"Selección del Reloj:\n" +
"- Seleccione la hora para cambiar el reloj\n" +
"- o presione  Shift-click para disminuirlo\n" +
"- o presione click y arrastre del ratón para una selección rapida.";

Calendar._TT["PREV_YEAR"] = "Año anterior (Presione para menu)";
Calendar._TT["PREV_MONTH"] = "Mes Anterior (Presione para menu)";
Calendar._TT["GO_TODAY"] = "Ir a Hoy";
Calendar._TT["NEXT_MONTH"] = "Mes Siguiente (Presione para menu)";
Calendar._TT["NEXT_YEAR"] = "Año Siguiente (Presione para menu)";
Calendar._TT["SEL_DATE"] = "Seleccione fecha";
Calendar._TT["DRAG_TO_MOVE"] = "Arrastre y mueva";
Calendar._TT["PART_TODAY"] = " (Hoy)";

// the following is to inform that "%s" is to be the first day of week
// %s will be replaced with the day name.
Calendar._TT["DAY_FIRST"] = "Mostrar %s primero";

// This may be locale-dependent.  It specifies the week-end days, as an array
// of comma-separated numbers.  The numbers are from 0 to 6: 0 means Sunday, 1
// means Monday, etc.
Calendar._TT["WEEKEND"] = "0,6";

Calendar._TT["CLOSE"] = "Cerrar";
Calendar._TT["TODAY"] = "Hoy";
Calendar._TT["TIME_PART"] = "(Shift-)Click o arrastra para cambar el valor";

// date formats
Calendar._TT["DEF_DATE_FORMAT"] = "%dd-%mm-%yy";
Calendar._TT["TT_DATE_FORMAT"] = "%A, %e de %B de %Y";

Calendar._TT["WK"] = "Sm";
Calendar._TT["TIME"] = "Hora:";
