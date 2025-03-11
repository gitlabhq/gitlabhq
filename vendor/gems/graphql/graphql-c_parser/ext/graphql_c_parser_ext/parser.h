#ifndef Graphql_parser_h
#define Graphql_parser_h
int yyparse(VALUE parser, VALUE filename);
void initialize_node_class_variables();
#endif
