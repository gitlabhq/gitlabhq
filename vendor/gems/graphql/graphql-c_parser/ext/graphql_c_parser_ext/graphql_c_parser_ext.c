#include "graphql_c_parser_ext.h"

VALUE GraphQL_CParser_Lexer_tokenize_with_c_internal(VALUE self, VALUE query_string, VALUE fstring_identifiers, VALUE reject_numbers_followed_by_names, VALUE max_tokens) {
  return tokenize(query_string, RTEST(fstring_identifiers), RTEST(reject_numbers_followed_by_names), FIX2INT(max_tokens));
}

VALUE GraphQL_CParser_Parser_c_parse(VALUE self) {
  yyparse(self, rb_ivar_get(self, rb_intern("@filename")));
  return Qnil;
}

void Init_graphql_c_parser_ext() {
  VALUE GraphQL = rb_define_module("GraphQL");
  VALUE CParser = rb_define_module_under(GraphQL, "CParser");
  VALUE Lexer = rb_define_module_under(CParser, "Lexer");
  rb_define_singleton_method(Lexer, "tokenize_with_c_internal", GraphQL_CParser_Lexer_tokenize_with_c_internal, 4);
  setup_static_token_variables();

  VALUE Parser = rb_define_class_under(CParser, "Parser", rb_cObject);
  rb_define_method(Parser, "c_parse", GraphQL_CParser_Parser_c_parse, 0);
  initialize_node_class_variables();
}
