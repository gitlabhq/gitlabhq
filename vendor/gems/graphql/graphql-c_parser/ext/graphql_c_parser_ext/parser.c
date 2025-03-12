/* A Bison parser, made by GNU Bison 3.8.2.  */

/* Bison implementation for Yacc-like parsers in C

   Copyright (C) 1984, 1989-1990, 2000-2015, 2018-2021 Free Software Foundation,
   Inc.

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <https://www.gnu.org/licenses/>.  */

/* As a special exception, you may create a larger work that contains
   part or all of the Bison parser skeleton and distribute that work
   under terms of your choice, so long as that work isn't itself a
   parser generator using the skeleton or a modified version thereof
   as a parser skeleton.  Alternatively, if you modify or redistribute
   the parser skeleton itself, you may (at your option) remove this
   special exception, which will cause the skeleton and the resulting
   Bison output files to be licensed under the GNU General Public
   License without this special exception.

   This special exception was added by the Free Software Foundation in
   version 2.2 of Bison.  */

/* C LALR(1) parser skeleton written by Richard Stallman, by
   simplifying the original so-called "semantic" parser.  */

/* DO NOT RELY ON FEATURES THAT ARE NOT DOCUMENTED in the manual,
   especially those whose name start with YY_ or yy_.  They are
   private implementation details that can be changed or removed.  */

/* All symbols defined below should begin with yy or YY, to avoid
   infringing on user name space.  This should be done even for local
   variables, as they might otherwise be expanded by user macros.
   There are some unavoidable exceptions within include files to
   define necessary library symbols; they are noted "INFRINGES ON
   USER NAME SPACE" below.  */

/* Identify Bison output, and Bison version.  */
#define YYBISON 30802

/* Bison version string.  */
#define YYBISON_VERSION "3.8.2"

/* Skeleton name.  */
#define YYSKELETON_NAME "yacc.c"

/* Pure parsers.  */
#define YYPURE 2

/* Push parsers.  */
#define YYPUSH 0

/* Pull parsers.  */
#define YYPULL 1




/* First part of user prologue.  */
#line 5 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"

// C Declarations
#include <ruby.h>
#define YYSTYPE VALUE
int yylex(YYSTYPE *, VALUE, VALUE);
void yyerror(VALUE, VALUE, const char*);

static VALUE GraphQL_Language_Nodes_NONE;
static VALUE r_string_query;

#define MAKE_AST_NODE(node_class_name, nargs, ...) rb_funcall(GraphQL_Language_Nodes_##node_class_name, rb_intern("from_a"), nargs + 1, filename,__VA_ARGS__)

#define SETUP_NODE_CLASS_VARIABLE(node_class_name) static VALUE GraphQL_Language_Nodes_##node_class_name;

SETUP_NODE_CLASS_VARIABLE(Argument)
SETUP_NODE_CLASS_VARIABLE(Directive)
SETUP_NODE_CLASS_VARIABLE(Document)
SETUP_NODE_CLASS_VARIABLE(Enum)
SETUP_NODE_CLASS_VARIABLE(Field)
SETUP_NODE_CLASS_VARIABLE(FragmentDefinition)
SETUP_NODE_CLASS_VARIABLE(FragmentSpread)
SETUP_NODE_CLASS_VARIABLE(InlineFragment)
SETUP_NODE_CLASS_VARIABLE(InputObject)
SETUP_NODE_CLASS_VARIABLE(ListType)
SETUP_NODE_CLASS_VARIABLE(NonNullType)
SETUP_NODE_CLASS_VARIABLE(NullValue)
SETUP_NODE_CLASS_VARIABLE(OperationDefinition)
SETUP_NODE_CLASS_VARIABLE(TypeName)
SETUP_NODE_CLASS_VARIABLE(VariableDefinition)
SETUP_NODE_CLASS_VARIABLE(VariableIdentifier)

SETUP_NODE_CLASS_VARIABLE(ScalarTypeDefinition)
SETUP_NODE_CLASS_VARIABLE(ObjectTypeDefinition)
SETUP_NODE_CLASS_VARIABLE(InterfaceTypeDefinition)
SETUP_NODE_CLASS_VARIABLE(UnionTypeDefinition)
SETUP_NODE_CLASS_VARIABLE(EnumTypeDefinition)
SETUP_NODE_CLASS_VARIABLE(InputObjectTypeDefinition)
SETUP_NODE_CLASS_VARIABLE(EnumValueDefinition)
SETUP_NODE_CLASS_VARIABLE(DirectiveDefinition)
SETUP_NODE_CLASS_VARIABLE(DirectiveLocation)
SETUP_NODE_CLASS_VARIABLE(FieldDefinition)
SETUP_NODE_CLASS_VARIABLE(InputValueDefinition)
SETUP_NODE_CLASS_VARIABLE(SchemaDefinition)

SETUP_NODE_CLASS_VARIABLE(ScalarTypeExtension)
SETUP_NODE_CLASS_VARIABLE(ObjectTypeExtension)
SETUP_NODE_CLASS_VARIABLE(InterfaceTypeExtension)
SETUP_NODE_CLASS_VARIABLE(UnionTypeExtension)
SETUP_NODE_CLASS_VARIABLE(EnumTypeExtension)
SETUP_NODE_CLASS_VARIABLE(InputObjectTypeExtension)
SETUP_NODE_CLASS_VARIABLE(SchemaExtension)

#line 124 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"

# ifndef YY_CAST
#  ifdef __cplusplus
#   define YY_CAST(Type, Val) static_cast<Type> (Val)
#   define YY_REINTERPRET_CAST(Type, Val) reinterpret_cast<Type> (Val)
#  else
#   define YY_CAST(Type, Val) ((Type) (Val))
#   define YY_REINTERPRET_CAST(Type, Val) ((Type) (Val))
#  endif
# endif
# ifndef YY_NULLPTR
#  if defined __cplusplus
#   if 201103L <= __cplusplus
#    define YY_NULLPTR nullptr
#   else
#    define YY_NULLPTR 0
#   endif
#  else
#   define YY_NULLPTR ((void*)0)
#  endif
# endif


/* Debug traces.  */
#ifndef YYDEBUG
# define YYDEBUG 0
#endif
#if YYDEBUG
extern int yydebug;
#endif

/* Token kinds.  */
#ifndef YYTOKENTYPE
# define YYTOKENTYPE
  enum yytokentype
  {
    YYEMPTY = -2,
    YYEOF = 0,                     /* "end of file"  */
    YYerror = 256,                 /* error  */
    YYUNDEF = 257,                 /* "invalid token"  */
    AMP = 200,                     /* AMP  */
    BANG = 201,                    /* BANG  */
    COLON = 202,                   /* COLON  */
    DIRECTIVE = 203,               /* DIRECTIVE  */
    DIR_SIGN = 204,                /* DIR_SIGN  */
    ENUM = 205,                    /* ENUM  */
    ELLIPSIS = 206,                /* ELLIPSIS  */
    EQUALS = 207,                  /* EQUALS  */
    EXTEND = 208,                  /* EXTEND  */
    FALSE_LITERAL = 209,           /* FALSE_LITERAL  */
    FLOAT = 210,                   /* FLOAT  */
    FRAGMENT = 211,                /* FRAGMENT  */
    IDENTIFIER = 212,              /* IDENTIFIER  */
    INPUT = 213,                   /* INPUT  */
    IMPLEMENTS = 214,              /* IMPLEMENTS  */
    INT = 215,                     /* INT  */
    INTERFACE = 216,               /* INTERFACE  */
    LBRACKET = 217,                /* LBRACKET  */
    LCURLY = 218,                  /* LCURLY  */
    LPAREN = 219,                  /* LPAREN  */
    MUTATION = 220,                /* MUTATION  */
    NULL_LITERAL = 221,            /* NULL_LITERAL  */
    ON = 222,                      /* ON  */
    PIPE = 223,                    /* PIPE  */
    QUERY = 224,                   /* QUERY  */
    RBRACKET = 225,                /* RBRACKET  */
    RCURLY = 226,                  /* RCURLY  */
    REPEATABLE = 227,              /* REPEATABLE  */
    RPAREN = 228,                  /* RPAREN  */
    SCALAR = 229,                  /* SCALAR  */
    SCHEMA = 230,                  /* SCHEMA  */
    STRING = 231,                  /* STRING  */
    SUBSCRIPTION = 232,            /* SUBSCRIPTION  */
    TRUE_LITERAL = 233,            /* TRUE_LITERAL  */
    TYPE_LITERAL = 234,            /* TYPE_LITERAL  */
    UNION = 235,                   /* UNION  */
    VAR_SIGN = 236                 /* VAR_SIGN  */
  };
  typedef enum yytokentype yytoken_kind_t;
#endif
/* Token kinds.  */
#define YYEMPTY -2
#define YYEOF 0
#define YYerror 256
#define YYUNDEF 257
#define AMP 200
#define BANG 201
#define COLON 202
#define DIRECTIVE 203
#define DIR_SIGN 204
#define ENUM 205
#define ELLIPSIS 206
#define EQUALS 207
#define EXTEND 208
#define FALSE_LITERAL 209
#define FLOAT 210
#define FRAGMENT 211
#define IDENTIFIER 212
#define INPUT 213
#define IMPLEMENTS 214
#define INT 215
#define INTERFACE 216
#define LBRACKET 217
#define LCURLY 218
#define LPAREN 219
#define MUTATION 220
#define NULL_LITERAL 221
#define ON 222
#define PIPE 223
#define QUERY 224
#define RBRACKET 225
#define RCURLY 226
#define REPEATABLE 227
#define RPAREN 228
#define SCALAR 229
#define SCHEMA 230
#define STRING 231
#define SUBSCRIPTION 232
#define TRUE_LITERAL 233
#define TYPE_LITERAL 234
#define UNION 235
#define VAR_SIGN 236

/* Value type.  */
#if ! defined YYSTYPE && ! defined YYSTYPE_IS_DECLARED
typedef int YYSTYPE;
# define YYSTYPE_IS_TRIVIAL 1
# define YYSTYPE_IS_DECLARED 1
#endif




int yyparse (VALUE parser, VALUE filename);



/* Symbol kind.  */
enum yysymbol_kind_t
{
  YYSYMBOL_YYEMPTY = -2,
  YYSYMBOL_YYEOF = 0,                      /* "end of file"  */
  YYSYMBOL_YYerror = 1,                    /* error  */
  YYSYMBOL_YYUNDEF = 2,                    /* "invalid token"  */
  YYSYMBOL_AMP = 3,                        /* AMP  */
  YYSYMBOL_BANG = 4,                       /* BANG  */
  YYSYMBOL_COLON = 5,                      /* COLON  */
  YYSYMBOL_DIRECTIVE = 6,                  /* DIRECTIVE  */
  YYSYMBOL_DIR_SIGN = 7,                   /* DIR_SIGN  */
  YYSYMBOL_ENUM = 8,                       /* ENUM  */
  YYSYMBOL_ELLIPSIS = 9,                   /* ELLIPSIS  */
  YYSYMBOL_EQUALS = 10,                    /* EQUALS  */
  YYSYMBOL_EXTEND = 11,                    /* EXTEND  */
  YYSYMBOL_FALSE_LITERAL = 12,             /* FALSE_LITERAL  */
  YYSYMBOL_FLOAT = 13,                     /* FLOAT  */
  YYSYMBOL_FRAGMENT = 14,                  /* FRAGMENT  */
  YYSYMBOL_IDENTIFIER = 15,                /* IDENTIFIER  */
  YYSYMBOL_INPUT = 16,                     /* INPUT  */
  YYSYMBOL_IMPLEMENTS = 17,                /* IMPLEMENTS  */
  YYSYMBOL_INT = 18,                       /* INT  */
  YYSYMBOL_INTERFACE = 19,                 /* INTERFACE  */
  YYSYMBOL_LBRACKET = 20,                  /* LBRACKET  */
  YYSYMBOL_LCURLY = 21,                    /* LCURLY  */
  YYSYMBOL_LPAREN = 22,                    /* LPAREN  */
  YYSYMBOL_MUTATION = 23,                  /* MUTATION  */
  YYSYMBOL_NULL_LITERAL = 24,              /* NULL_LITERAL  */
  YYSYMBOL_ON = 25,                        /* ON  */
  YYSYMBOL_PIPE = 26,                      /* PIPE  */
  YYSYMBOL_QUERY = 27,                     /* QUERY  */
  YYSYMBOL_RBRACKET = 28,                  /* RBRACKET  */
  YYSYMBOL_RCURLY = 29,                    /* RCURLY  */
  YYSYMBOL_REPEATABLE = 30,                /* REPEATABLE  */
  YYSYMBOL_RPAREN = 31,                    /* RPAREN  */
  YYSYMBOL_SCALAR = 32,                    /* SCALAR  */
  YYSYMBOL_SCHEMA = 33,                    /* SCHEMA  */
  YYSYMBOL_STRING = 34,                    /* STRING  */
  YYSYMBOL_SUBSCRIPTION = 35,              /* SUBSCRIPTION  */
  YYSYMBOL_TRUE_LITERAL = 36,              /* TRUE_LITERAL  */
  YYSYMBOL_TYPE_LITERAL = 37,              /* TYPE_LITERAL  */
  YYSYMBOL_UNION = 38,                     /* UNION  */
  YYSYMBOL_VAR_SIGN = 39,                  /* VAR_SIGN  */
  YYSYMBOL_YYACCEPT = 40,                  /* $accept  */
  YYSYMBOL_start = 41,                     /* start  */
  YYSYMBOL_document = 42,                  /* document  */
  YYSYMBOL_definitions_list = 43,          /* definitions_list  */
  YYSYMBOL_definition = 44,                /* definition  */
  YYSYMBOL_executable_definition = 45,     /* executable_definition  */
  YYSYMBOL_operation_definition = 46,      /* operation_definition  */
  YYSYMBOL_operation_type = 47,            /* operation_type  */
  YYSYMBOL_operation_name_opt = 48,        /* operation_name_opt  */
  YYSYMBOL_variable_definitions_opt = 49,  /* variable_definitions_opt  */
  YYSYMBOL_variable_definitions_list = 50, /* variable_definitions_list  */
  YYSYMBOL_variable_definition = 51,       /* variable_definition  */
  YYSYMBOL_default_value_opt = 52,         /* default_value_opt  */
  YYSYMBOL_selection_list = 53,            /* selection_list  */
  YYSYMBOL_selection = 54,                 /* selection  */
  YYSYMBOL_selection_set = 55,             /* selection_set  */
  YYSYMBOL_selection_set_opt = 56,         /* selection_set_opt  */
  YYSYMBOL_field = 57,                     /* field  */
  YYSYMBOL_arguments_opt = 58,             /* arguments_opt  */
  YYSYMBOL_arguments_list = 59,            /* arguments_list  */
  YYSYMBOL_argument = 60,                  /* argument  */
  YYSYMBOL_literal_value = 61,             /* literal_value  */
  YYSYMBOL_input_value = 62,               /* input_value  */
  YYSYMBOL_null_value = 63,                /* null_value  */
  YYSYMBOL_variable = 64,                  /* variable  */
  YYSYMBOL_list_value = 65,                /* list_value  */
  YYSYMBOL_list_value_list = 66,           /* list_value_list  */
  YYSYMBOL_enum_name = 67,                 /* enum_name  */
  YYSYMBOL_enum_value = 68,                /* enum_value  */
  YYSYMBOL_object_value = 69,              /* object_value  */
  YYSYMBOL_object_value_list_opt = 70,     /* object_value_list_opt  */
  YYSYMBOL_object_value_list = 71,         /* object_value_list  */
  YYSYMBOL_object_value_field = 72,        /* object_value_field  */
  YYSYMBOL_object_literal_value = 73,      /* object_literal_value  */
  YYSYMBOL_object_literal_value_list_opt = 74, /* object_literal_value_list_opt  */
  YYSYMBOL_object_literal_value_list = 75, /* object_literal_value_list  */
  YYSYMBOL_object_literal_value_field = 76, /* object_literal_value_field  */
  YYSYMBOL_directives_list_opt = 77,       /* directives_list_opt  */
  YYSYMBOL_directives_list = 78,           /* directives_list  */
  YYSYMBOL_directive = 79,                 /* directive  */
  YYSYMBOL_name = 80,                      /* name  */
  YYSYMBOL_schema_keyword = 81,            /* schema_keyword  */
  YYSYMBOL_name_without_on = 82,           /* name_without_on  */
  YYSYMBOL_fragment_spread = 83,           /* fragment_spread  */
  YYSYMBOL_inline_fragment = 84,           /* inline_fragment  */
  YYSYMBOL_fragment_definition = 85,       /* fragment_definition  */
  YYSYMBOL_fragment_name_opt = 86,         /* fragment_name_opt  */
  YYSYMBOL_type = 87,                      /* type  */
  YYSYMBOL_nullable_type = 88,             /* nullable_type  */
  YYSYMBOL_type_system_definition = 89,    /* type_system_definition  */
  YYSYMBOL_schema_definition = 90,         /* schema_definition  */
  YYSYMBOL_operation_type_definition_list_opt = 91, /* operation_type_definition_list_opt  */
  YYSYMBOL_operation_type_definition_list = 92, /* operation_type_definition_list  */
  YYSYMBOL_operation_type_definition = 93, /* operation_type_definition  */
  YYSYMBOL_type_definition = 94,           /* type_definition  */
  YYSYMBOL_description = 95,               /* description  */
  YYSYMBOL_description_opt = 96,           /* description_opt  */
  YYSYMBOL_scalar_type_definition = 97,    /* scalar_type_definition  */
  YYSYMBOL_object_type_definition = 98,    /* object_type_definition  */
  YYSYMBOL_implements_opt = 99,            /* implements_opt  */
  YYSYMBOL_interfaces_list = 100,          /* interfaces_list  */
  YYSYMBOL_legacy_interfaces_list = 101,   /* legacy_interfaces_list  */
  YYSYMBOL_input_value_definition = 102,   /* input_value_definition  */
  YYSYMBOL_input_value_definition_list = 103, /* input_value_definition_list  */
  YYSYMBOL_arguments_definitions_opt = 104, /* arguments_definitions_opt  */
  YYSYMBOL_field_definition = 105,         /* field_definition  */
  YYSYMBOL_field_definition_list_opt = 106, /* field_definition_list_opt  */
  YYSYMBOL_field_definition_list = 107,    /* field_definition_list  */
  YYSYMBOL_interface_type_definition = 108, /* interface_type_definition  */
  YYSYMBOL_pipe_opt = 109,                 /* pipe_opt  */
  YYSYMBOL_union_members = 110,            /* union_members  */
  YYSYMBOL_union_type_definition = 111,    /* union_type_definition  */
  YYSYMBOL_enum_type_definition = 112,     /* enum_type_definition  */
  YYSYMBOL_enum_value_definition = 113,    /* enum_value_definition  */
  YYSYMBOL_enum_value_definitions = 114,   /* enum_value_definitions  */
  YYSYMBOL_input_object_type_definition = 115, /* input_object_type_definition  */
  YYSYMBOL_directive_definition = 116,     /* directive_definition  */
  YYSYMBOL_directive_repeatable_opt = 117, /* directive_repeatable_opt  */
  YYSYMBOL_directive_locations = 118,      /* directive_locations  */
  YYSYMBOL_type_system_extension = 119,    /* type_system_extension  */
  YYSYMBOL_schema_extension = 120,         /* schema_extension  */
  YYSYMBOL_type_extension = 121,           /* type_extension  */
  YYSYMBOL_scalar_type_extension = 122,    /* scalar_type_extension  */
  YYSYMBOL_object_type_extension = 123,    /* object_type_extension  */
  YYSYMBOL_interface_type_extension = 124, /* interface_type_extension  */
  YYSYMBOL_union_type_extension = 125,     /* union_type_extension  */
  YYSYMBOL_enum_type_extension = 126,      /* enum_type_extension  */
  YYSYMBOL_input_object_type_extension = 127 /* input_object_type_extension  */
};
typedef enum yysymbol_kind_t yysymbol_kind_t;




#ifdef short
# undef short
#endif

/* On compilers that do not define __PTRDIFF_MAX__ etc., make sure
   <limits.h> and (if available) <stdint.h> are included
   so that the code can choose integer types of a good width.  */

#ifndef __PTRDIFF_MAX__
# include <limits.h> /* INFRINGES ON USER NAME SPACE */
# if defined __STDC_VERSION__ && 199901 <= __STDC_VERSION__
#  include <stdint.h> /* INFRINGES ON USER NAME SPACE */
#  define YY_STDINT_H
# endif
#endif

/* Narrow types that promote to a signed type and that can represent a
   signed or unsigned integer of at least N bits.  In tables they can
   save space and decrease cache pressure.  Promoting to a signed type
   helps avoid bugs in integer arithmetic.  */

#ifdef __INT_LEAST8_MAX__
typedef __INT_LEAST8_TYPE__ yytype_int8;
#elif defined YY_STDINT_H
typedef int_least8_t yytype_int8;
#else
typedef signed char yytype_int8;
#endif

#ifdef __INT_LEAST16_MAX__
typedef __INT_LEAST16_TYPE__ yytype_int16;
#elif defined YY_STDINT_H
typedef int_least16_t yytype_int16;
#else
typedef short yytype_int16;
#endif

/* Work around bug in HP-UX 11.23, which defines these macros
   incorrectly for preprocessor constants.  This workaround can likely
   be removed in 2023, as HPE has promised support for HP-UX 11.23
   (aka HP-UX 11i v2) only through the end of 2022; see Table 2 of
   <https://h20195.www2.hpe.com/V2/getpdf.aspx/4AA4-7673ENW.pdf>.  */
#ifdef __hpux
# undef UINT_LEAST8_MAX
# undef UINT_LEAST16_MAX
# define UINT_LEAST8_MAX 255
# define UINT_LEAST16_MAX 65535
#endif

#if defined __UINT_LEAST8_MAX__ && __UINT_LEAST8_MAX__ <= __INT_MAX__
typedef __UINT_LEAST8_TYPE__ yytype_uint8;
#elif (!defined __UINT_LEAST8_MAX__ && defined YY_STDINT_H \
       && UINT_LEAST8_MAX <= INT_MAX)
typedef uint_least8_t yytype_uint8;
#elif !defined __UINT_LEAST8_MAX__ && UCHAR_MAX <= INT_MAX
typedef unsigned char yytype_uint8;
#else
typedef short yytype_uint8;
#endif

#if defined __UINT_LEAST16_MAX__ && __UINT_LEAST16_MAX__ <= __INT_MAX__
typedef __UINT_LEAST16_TYPE__ yytype_uint16;
#elif (!defined __UINT_LEAST16_MAX__ && defined YY_STDINT_H \
       && UINT_LEAST16_MAX <= INT_MAX)
typedef uint_least16_t yytype_uint16;
#elif !defined __UINT_LEAST16_MAX__ && USHRT_MAX <= INT_MAX
typedef unsigned short yytype_uint16;
#else
typedef int yytype_uint16;
#endif

#ifndef YYPTRDIFF_T
# if defined __PTRDIFF_TYPE__ && defined __PTRDIFF_MAX__
#  define YYPTRDIFF_T __PTRDIFF_TYPE__
#  define YYPTRDIFF_MAXIMUM __PTRDIFF_MAX__
# elif defined PTRDIFF_MAX
#  ifndef ptrdiff_t
#   include <stddef.h> /* INFRINGES ON USER NAME SPACE */
#  endif
#  define YYPTRDIFF_T ptrdiff_t
#  define YYPTRDIFF_MAXIMUM PTRDIFF_MAX
# else
#  define YYPTRDIFF_T long
#  define YYPTRDIFF_MAXIMUM LONG_MAX
# endif
#endif

#ifndef YYSIZE_T
# ifdef __SIZE_TYPE__
#  define YYSIZE_T __SIZE_TYPE__
# elif defined size_t
#  define YYSIZE_T size_t
# elif defined __STDC_VERSION__ && 199901 <= __STDC_VERSION__
#  include <stddef.h> /* INFRINGES ON USER NAME SPACE */
#  define YYSIZE_T size_t
# else
#  define YYSIZE_T unsigned
# endif
#endif

#define YYSIZE_MAXIMUM                                  \
  YY_CAST (YYPTRDIFF_T,                                 \
           (YYPTRDIFF_MAXIMUM < YY_CAST (YYSIZE_T, -1)  \
            ? YYPTRDIFF_MAXIMUM                         \
            : YY_CAST (YYSIZE_T, -1)))

#define YYSIZEOF(X) YY_CAST (YYPTRDIFF_T, sizeof (X))


/* Stored state numbers (used for stacks). */
typedef yytype_int16 yy_state_t;

/* State numbers in computations.  */
typedef int yy_state_fast_t;

#ifndef YY_
# if defined YYENABLE_NLS && YYENABLE_NLS
#  if ENABLE_NLS
#   include <libintl.h> /* INFRINGES ON USER NAME SPACE */
#   define YY_(Msgid) dgettext ("bison-runtime", Msgid)
#  endif
# endif
# ifndef YY_
#  define YY_(Msgid) Msgid
# endif
#endif


#ifndef YY_ATTRIBUTE_PURE
# if defined __GNUC__ && 2 < __GNUC__ + (96 <= __GNUC_MINOR__)
#  define YY_ATTRIBUTE_PURE __attribute__ ((__pure__))
# else
#  define YY_ATTRIBUTE_PURE
# endif
#endif

#ifndef YY_ATTRIBUTE_UNUSED
# if defined __GNUC__ && 2 < __GNUC__ + (7 <= __GNUC_MINOR__)
#  define YY_ATTRIBUTE_UNUSED __attribute__ ((__unused__))
# else
#  define YY_ATTRIBUTE_UNUSED
# endif
#endif

/* Suppress unused-variable warnings by "using" E.  */
#if ! defined lint || defined __GNUC__
# define YY_USE(E) ((void) (E))
#else
# define YY_USE(E) /* empty */
#endif

/* Suppress an incorrect diagnostic about yylval being uninitialized.  */
#if defined __GNUC__ && ! defined __ICC && 406 <= __GNUC__ * 100 + __GNUC_MINOR__
# if __GNUC__ * 100 + __GNUC_MINOR__ < 407
#  define YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN                           \
    _Pragma ("GCC diagnostic push")                                     \
    _Pragma ("GCC diagnostic ignored \"-Wuninitialized\"")
# else
#  define YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN                           \
    _Pragma ("GCC diagnostic push")                                     \
    _Pragma ("GCC diagnostic ignored \"-Wuninitialized\"")              \
    _Pragma ("GCC diagnostic ignored \"-Wmaybe-uninitialized\"")
# endif
# define YY_IGNORE_MAYBE_UNINITIALIZED_END      \
    _Pragma ("GCC diagnostic pop")
#else
# define YY_INITIAL_VALUE(Value) Value
#endif
#ifndef YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
# define YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
# define YY_IGNORE_MAYBE_UNINITIALIZED_END
#endif
#ifndef YY_INITIAL_VALUE
# define YY_INITIAL_VALUE(Value) /* Nothing. */
#endif

#if defined __cplusplus && defined __GNUC__ && ! defined __ICC && 6 <= __GNUC__
# define YY_IGNORE_USELESS_CAST_BEGIN                          \
    _Pragma ("GCC diagnostic push")                            \
    _Pragma ("GCC diagnostic ignored \"-Wuseless-cast\"")
# define YY_IGNORE_USELESS_CAST_END            \
    _Pragma ("GCC diagnostic pop")
#endif
#ifndef YY_IGNORE_USELESS_CAST_BEGIN
# define YY_IGNORE_USELESS_CAST_BEGIN
# define YY_IGNORE_USELESS_CAST_END
#endif


#define YY_ASSERT(E) ((void) (0 && (E)))

#if 1

/* The parser invokes alloca or malloc; define the necessary symbols.  */

# ifdef YYSTACK_USE_ALLOCA
#  if YYSTACK_USE_ALLOCA
#   ifdef __GNUC__
#    define YYSTACK_ALLOC __builtin_alloca
#   elif defined __BUILTIN_VA_ARG_INCR
#    include <alloca.h> /* INFRINGES ON USER NAME SPACE */
#   elif defined _AIX
#    define YYSTACK_ALLOC __alloca
#   elif defined _MSC_VER
#    include <malloc.h> /* INFRINGES ON USER NAME SPACE */
#    define alloca _alloca
#   else
#    define YYSTACK_ALLOC alloca
#    if ! defined _ALLOCA_H && ! defined EXIT_SUCCESS
#     include <stdlib.h> /* INFRINGES ON USER NAME SPACE */
      /* Use EXIT_SUCCESS as a witness for stdlib.h.  */
#     ifndef EXIT_SUCCESS
#      define EXIT_SUCCESS 0
#     endif
#    endif
#   endif
#  endif
# endif

# ifdef YYSTACK_ALLOC
   /* Pacify GCC's 'empty if-body' warning.  */
#  define YYSTACK_FREE(Ptr) do { /* empty */; } while (0)
#  ifndef YYSTACK_ALLOC_MAXIMUM
    /* The OS might guarantee only one guard page at the bottom of the stack,
       and a page size can be as small as 4096 bytes.  So we cannot safely
       invoke alloca (N) if N exceeds 4096.  Use a slightly smaller number
       to allow for a few compiler-allocated temporary stack slots.  */
#   define YYSTACK_ALLOC_MAXIMUM 4032 /* reasonable circa 2006 */
#  endif
# else
#  define YYSTACK_ALLOC YYMALLOC
#  define YYSTACK_FREE YYFREE
#  ifndef YYSTACK_ALLOC_MAXIMUM
#   define YYSTACK_ALLOC_MAXIMUM YYSIZE_MAXIMUM
#  endif
#  if (defined __cplusplus && ! defined EXIT_SUCCESS \
       && ! ((defined YYMALLOC || defined malloc) \
             && (defined YYFREE || defined free)))
#   include <stdlib.h> /* INFRINGES ON USER NAME SPACE */
#   ifndef EXIT_SUCCESS
#    define EXIT_SUCCESS 0
#   endif
#  endif
#  ifndef YYMALLOC
#   define YYMALLOC malloc
#   if ! defined malloc && ! defined EXIT_SUCCESS
void *malloc (YYSIZE_T); /* INFRINGES ON USER NAME SPACE */
#   endif
#  endif
#  ifndef YYFREE
#   define YYFREE free
#   if ! defined free && ! defined EXIT_SUCCESS
void free (void *); /* INFRINGES ON USER NAME SPACE */
#   endif
#  endif
# endif
#endif /* 1 */

#if (! defined yyoverflow \
     && (! defined __cplusplus \
         || (defined YYSTYPE_IS_TRIVIAL && YYSTYPE_IS_TRIVIAL)))

/* A type that is properly aligned for any stack member.  */
union yyalloc
{
  yy_state_t yyss_alloc;
  YYSTYPE yyvs_alloc;
};

/* The size of the maximum gap between one aligned stack and the next.  */
# define YYSTACK_GAP_MAXIMUM (YYSIZEOF (union yyalloc) - 1)

/* The size of an array large to enough to hold all stacks, each with
   N elements.  */
# define YYSTACK_BYTES(N) \
     ((N) * (YYSIZEOF (yy_state_t) + YYSIZEOF (YYSTYPE)) \
      + YYSTACK_GAP_MAXIMUM)

# define YYCOPY_NEEDED 1

/* Relocate STACK from its old location to the new one.  The
   local variables YYSIZE and YYSTACKSIZE give the old and new number of
   elements in the stack, and YYPTR gives the new location of the
   stack.  Advance YYPTR to a properly aligned location for the next
   stack.  */
# define YYSTACK_RELOCATE(Stack_alloc, Stack)                           \
    do                                                                  \
      {                                                                 \
        YYPTRDIFF_T yynewbytes;                                         \
        YYCOPY (&yyptr->Stack_alloc, Stack, yysize);                    \
        Stack = &yyptr->Stack_alloc;                                    \
        yynewbytes = yystacksize * YYSIZEOF (*Stack) + YYSTACK_GAP_MAXIMUM; \
        yyptr += yynewbytes / YYSIZEOF (*yyptr);                        \
      }                                                                 \
    while (0)

#endif

#if defined YYCOPY_NEEDED && YYCOPY_NEEDED
/* Copy COUNT objects from SRC to DST.  The source and destination do
   not overlap.  */
# ifndef YYCOPY
#  if defined __GNUC__ && 1 < __GNUC__
#   define YYCOPY(Dst, Src, Count) \
      __builtin_memcpy (Dst, Src, YY_CAST (YYSIZE_T, (Count)) * sizeof (*(Src)))
#  else
#   define YYCOPY(Dst, Src, Count)              \
      do                                        \
        {                                       \
          YYPTRDIFF_T yyi;                      \
          for (yyi = 0; yyi < (Count); yyi++)   \
            (Dst)[yyi] = (Src)[yyi];            \
        }                                       \
      while (0)
#  endif
# endif
#endif /* !YYCOPY_NEEDED */

/* YYFINAL -- State number of the termination state.  */
#define YYFINAL  79
/* YYLAST -- Last index in YYTABLE.  */
#define YYLAST   777

/* YYNTOKENS -- Number of terminals.  */
#define YYNTOKENS  40
/* YYNNTS -- Number of nonterminals.  */
#define YYNNTS  88
/* YYNRULES -- Number of rules.  */
#define YYNRULES  184
/* YYNSTATES -- Number of states.  */
#define YYNSTATES  313

/* YYMAXUTOK -- Last valid token kind.  */
#define YYMAXUTOK   257


/* YYTRANSLATE(TOKEN-NUM) -- Symbol number corresponding to TOKEN-NUM
   as returned by yylex, with out-of-bounds checking.  */
#define YYTRANSLATE(YYX)                                \
  (0 <= (YYX) && (YYX) <= YYMAXUTOK                     \
   ? YY_CAST (yysymbol_kind_t, yytranslate[YYX])        \
   : YYSYMBOL_YYUNDEF)

/* YYTRANSLATE[TOKEN-NUM] -- Symbol number corresponding to TOKEN-NUM
   as returned by yylex.  */
static const yytype_int8 yytranslate[] =
{
       0,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       3,     4,     5,     6,     7,     8,     9,    10,    11,    12,
      13,    14,    15,    16,    17,    18,    19,    20,    21,    22,
      23,    24,    25,    26,    27,    28,    29,    30,    31,    32,
      33,    34,    35,    36,    37,    38,    39,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     1,     2
};

#if YYDEBUG
/* YYRLINE[YYN] -- Source line where rule number YYN was defined.  */
static const yytype_int16 yyrline[] =
{
       0,   103,   103,   105,   119,   120,   123,   124,   125,   128,
     129,   132,   143,   154,   167,   168,   169,   172,   173,   176,
     177,   180,   181,   184,   196,   197,   200,   201,   204,   205,
     206,   209,   212,   213,   216,   227,   240,   241,   244,   245,
     248,   258,   259,   260,   261,   262,   263,   264,   265,   266,
     269,   270,   271,   273,   281,   290,   291,   294,   295,   298,
     299,   300,   301,   303,   312,   321,   322,   325,   326,   329,
     340,   349,   350,   353,   354,   357,   368,   369,   372,   373,
     375,   385,   386,   389,   390,   391,   392,   393,   394,   395,
     396,   397,   398,   399,   400,   403,   404,   405,   406,   407,
     408,   412,   422,   431,   442,   454,   455,   458,   459,   462,
     469,   478,   479,   480,   483,   496,   497,   500,   504,   509,
     514,   515,   516,   517,   518,   519,   521,   524,   525,   528,
     540,   554,   555,   556,   557,   560,   568,   574,   582,   587,
     601,   602,   605,   606,   609,   623,   624,   627,   628,   629,
     632,   646,   647,   650,   658,   663,   676,   689,   701,   702,
     705,   718,   732,   733,   736,   737,   741,   742,   745,   756,
     768,   769,   770,   771,   772,   773,   775,   785,   797,   809,
     818,   829,   838,   849,   858
};
#endif

/** Accessing symbol of state STATE.  */
#define YY_ACCESSING_SYMBOL(State) YY_CAST (yysymbol_kind_t, yystos[State])

#if 1
/* The user-facing name of the symbol whose (internal) number is
   YYSYMBOL.  No bounds checking.  */
static const char *yysymbol_name (yysymbol_kind_t yysymbol) YY_ATTRIBUTE_UNUSED;

static const char *
yysymbol_name (yysymbol_kind_t yysymbol)
{
  static const char *const yy_sname[] =
  {
  "end of file", "error", "invalid token", "AMP", "BANG", "COLON",
  "DIRECTIVE", "DIR_SIGN", "ENUM", "ELLIPSIS", "EQUALS", "EXTEND",
  "FALSE_LITERAL", "FLOAT", "FRAGMENT", "IDENTIFIER", "INPUT",
  "IMPLEMENTS", "INT", "INTERFACE", "LBRACKET", "LCURLY", "LPAREN",
  "MUTATION", "NULL_LITERAL", "ON", "PIPE", "QUERY", "RBRACKET", "RCURLY",
  "REPEATABLE", "RPAREN", "SCALAR", "SCHEMA", "STRING", "SUBSCRIPTION",
  "TRUE_LITERAL", "TYPE_LITERAL", "UNION", "VAR_SIGN", "$accept", "start",
  "document", "definitions_list", "definition", "executable_definition",
  "operation_definition", "operation_type", "operation_name_opt",
  "variable_definitions_opt", "variable_definitions_list",
  "variable_definition", "default_value_opt", "selection_list",
  "selection", "selection_set", "selection_set_opt", "field",
  "arguments_opt", "arguments_list", "argument", "literal_value",
  "input_value", "null_value", "variable", "list_value", "list_value_list",
  "enum_name", "enum_value", "object_value", "object_value_list_opt",
  "object_value_list", "object_value_field", "object_literal_value",
  "object_literal_value_list_opt", "object_literal_value_list",
  "object_literal_value_field", "directives_list_opt", "directives_list",
  "directive", "name", "schema_keyword", "name_without_on",
  "fragment_spread", "inline_fragment", "fragment_definition",
  "fragment_name_opt", "type", "nullable_type", "type_system_definition",
  "schema_definition", "operation_type_definition_list_opt",
  "operation_type_definition_list", "operation_type_definition",
  "type_definition", "description", "description_opt",
  "scalar_type_definition", "object_type_definition", "implements_opt",
  "interfaces_list", "legacy_interfaces_list", "input_value_definition",
  "input_value_definition_list", "arguments_definitions_opt",
  "field_definition", "field_definition_list_opt", "field_definition_list",
  "interface_type_definition", "pipe_opt", "union_members",
  "union_type_definition", "enum_type_definition", "enum_value_definition",
  "enum_value_definitions", "input_object_type_definition",
  "directive_definition", "directive_repeatable_opt",
  "directive_locations", "type_system_extension", "schema_extension",
  "type_extension", "scalar_type_extension", "object_type_extension",
  "interface_type_extension", "union_type_extension",
  "enum_type_extension", "input_object_type_extension", YY_NULLPTR
  };
  return yy_sname[yysymbol];
}
#endif

#define YYPACT_NINF (-195)

#define yypact_value_is_default(Yyn) \
  ((Yyn) == YYPACT_NINF)

#define YYTABLE_NINF (-148)

#define yytable_value_is_error(Yyn) \
  0

/* YYPACT[STATE-NUM] -- Index in YYTABLE of the portion describing
   STATE-NUM.  */
static const yytype_int16 yypact[] =
{
     234,   155,   739,   475,  -195,  -195,     4,  -195,  -195,    44,
    -195,    95,  -195,  -195,  -195,   706,  -195,  -195,  -195,  -195,
    -195,    15,  -195,  -195,  -195,  -195,  -195,  -195,  -195,  -195,
    -195,  -195,  -195,  -195,  -195,  -195,  -195,  -195,   706,   706,
     706,   706,     4,   706,   706,  -195,  -195,  -195,  -195,  -195,
    -195,  -195,  -195,  -195,  -195,  -195,  -195,  -195,  -195,  -195,
    -195,  -195,  -195,  -195,    48,   574,  -195,  -195,   508,  -195,
    -195,    10,  -195,  -195,  -195,   706,    24,     4,  -195,  -195,
    -195,    58,  -195,    81,   706,   706,   706,   706,   706,   706,
       4,     4,    77,     4,    82,     7,    77,     4,   607,   607,
      83,     4,  -195,  -195,   706,   706,     4,    89,    73,  -195,
    -195,    74,     4,   706,     4,     4,    77,     4,    77,     4,
      91,     7,    93,     7,   306,     4,     4,    73,     4,   113,
      19,   607,  -195,     4,   111,     4,   640,  -195,  -195,    89,
     673,  -195,   127,    83,  -195,   138,   115,  -195,   706,   -15,
    -195,    83,   132,   135,   136,     4,  -195,     4,   166,   144,
     144,   706,   261,   176,   706,   160,   137,   160,   156,   157,
      83,  -195,    83,   541,     4,  -195,  -195,   408,  -195,  -195,
     706,  -195,  -195,   178,  -195,  -195,  -195,   144,   154,   144,
     144,   160,   160,   156,   205,  -195,    20,   706,  -195,    32,
    -195,   176,   706,  -195,    41,  -195,  -195,  -195,  -195,   706,
     164,  -195,  -195,  -195,  -195,    83,  -195,  -195,  -195,  -195,
     340,   706,  -195,  -195,  -195,  -195,   706,  -195,  -195,  -195,
    -195,  -195,  -195,  -195,  -195,  -195,  -195,  -195,  -195,   607,
      -4,  -195,   171,   105,   118,  -195,  -195,   164,     4,  -195,
    -195,   192,  -195,  -195,  -195,   706,  -195,   139,  -195,   706,
    -195,  -195,  -195,   374,   169,   706,  -195,   172,   706,  -195,
     195,  -195,   194,  -195,   706,  -195,  -195,  -195,   607,   132,
    -195,  -195,  -195,  -195,  -195,  -195,  -195,   200,  -195,  -195,
     202,   408,   442,     4,  -195,   186,   194,   209,   408,   442,
    -195,  -195,   706,  -195,  -195,   706,     4,   607,  -195,  -195,
    -195,     4,  -195
};

/* YYDEFACT[STATE-NUM] -- Default reduction number in state STATE-NUM.
   Performed when YYTABLE does not specify something else to do.  Zero
   means the default is an error.  */
static const yytype_uint8 yydefact[] =
{
     127,     0,   105,     0,    15,    14,    76,   126,    16,     0,
       2,   127,     4,     6,     9,    17,    10,     7,   111,   112,
     128,     0,   120,   121,   122,   123,   124,   125,   113,     8,
     166,   167,   170,   171,   172,   173,   174,   175,     0,     0,
       0,     0,    76,     0,     0,    91,    89,    92,    97,    93,
      95,    90,    86,    87,    98,    94,    84,    83,    96,    85,
      88,    99,   100,   106,     0,    76,    82,    13,     0,    26,
      28,    36,    81,    29,    30,     0,   115,    77,    78,     1,
       5,    19,    18,     0,     0,     0,     0,     0,     0,     0,
      76,    76,   131,     0,     0,   169,   131,    76,     0,     0,
       0,    76,    12,    27,     0,     0,    76,    36,     0,   114,
      79,     0,    76,     0,    76,    76,   131,    76,   131,    76,
       0,   182,     0,   184,     0,    76,   176,     0,    76,     0,
     180,     0,   109,    76,   107,    76,     0,   103,   101,    36,
       0,    38,     0,    32,    80,     0,     0,   117,     0,     0,
      21,     0,   142,     0,     0,    76,   129,    76,     0,   127,
     127,     0,   135,   133,   134,   145,     0,   145,   151,     0,
       0,   108,     0,     0,    76,    37,    39,     0,    33,    35,
       0,   116,   118,     0,    20,    22,    11,   127,   162,   127,
     127,   145,   145,   151,     0,   158,   127,     0,   140,   127,
     135,   132,     0,   138,   127,   178,   168,   177,   152,     0,
     179,   110,   104,   102,    31,    32,    45,    41,    59,    42,
       0,    65,    53,    60,    43,    44,     0,    61,    50,    40,
      46,    51,    48,    63,    47,    52,    49,    62,   119,     0,
     127,   163,     0,   127,   127,   150,   130,   155,    76,   181,
     159,     0,   183,   141,   136,     0,   148,   127,   153,     0,
      34,    55,    57,     0,     0,    66,    67,     0,    72,    73,
       0,    54,    24,   143,     0,   156,   160,   157,     0,   142,
     146,   149,   154,    56,    58,    64,    68,     0,    70,    74,
       0,     0,     0,    76,   164,   161,    24,     0,     0,     0,
      50,    69,    71,    25,    23,     0,    76,     0,    75,   165,
     139,    76,   144
};

/* YYPGOTO[NTERM-NUM].  */
static const yytype_int16 yypgoto[] =
{
    -195,  -195,  -195,  -195,   204,  -195,  -195,     9,  -195,  -195,
    -195,    68,   -71,    90,   -66,   -93,    12,  -195,   -89,  -195,
      94,  -194,  -174,  -195,  -195,  -195,  -195,    37,  -195,  -195,
    -195,  -195,   -32,  -195,  -195,  -195,   -29,    34,   -34,   -52,
      -3,  -172,     2,  -195,  -195,  -195,  -195,   -98,  -195,  -195,
    -195,  -195,   109,  -127,  -195,  -195,     6,  -195,  -195,   -54,
      80,  -195,  -189,  -100,   -35,   -11,   -99,  -195,  -195,  -195,
      54,  -195,  -195,  -183,    61,  -195,  -195,  -195,  -195,  -195,
    -195,  -195,  -195,  -195,  -195,  -195,  -195,  -195
};

/* YYDEFGOTO[NTERM-NUM].  */
static const yytype_int16 yydefgoto[] =
{
       0,     9,    10,    11,    12,    13,    14,    61,    81,   112,
     149,   150,   293,    68,    69,   178,   179,    70,   106,   140,
     141,   228,   301,   230,   231,   232,   263,   233,   234,   235,
     264,   265,   266,   236,   267,   268,   269,    76,    77,    78,
     132,    62,    72,    73,    74,    16,    64,   133,   134,    17,
      18,   109,   146,   147,    19,    20,   197,    22,    23,   125,
     163,   164,   198,   199,   188,   256,   205,   257,    24,   209,
     210,    25,    26,   195,   196,    27,    28,   242,   295,    29,
      30,    31,    32,    33,    34,    35,    36,    37
};

/* YYTABLE[YYPACT[STATE-NUM]] -- What to do in state STATE-NUM.  If
   positive, shift that token.  If negative, reduce the rule whose
   number is the opposite.  If YYTABLE_NINF, syntax error.  */
static const yytype_int16 yytable[] =
{
      71,   135,   103,   229,    63,   237,    21,   137,    95,    15,
     253,    75,    82,   250,    75,   104,   184,    21,   144,   182,
      15,    83,   237,    84,   148,   110,    75,   273,   -77,   -77,
       7,    85,   105,   169,    86,    90,    91,    92,    93,   182,
      96,    97,   128,   110,    79,   108,   262,    87,   237,   249,
     174,   253,    88,    89,     7,   253,   121,   123,   186,   126,
     250,   252,   155,   130,   157,    71,     7,   101,   207,   110,
    -147,   110,   107,    98,   110,     7,    94,   212,   110,   213,
     111,   114,   115,   116,   117,   118,   119,   240,   113,   284,
     244,   237,   245,   246,   124,    -3,     4,   300,   303,   100,
       5,   139,   142,   127,   136,   308,     1,   103,     8,     2,
     152,   105,   159,   148,   160,   171,     3,   145,     4,   237,
     237,   162,     5,   168,   120,   122,   237,   237,     6,     7,
       8,   129,   177,    71,   275,   138,   145,   142,     4,     7,
     143,   272,     5,   180,   181,   183,   151,   276,   153,   154,
       8,   156,     7,   158,   187,   145,   189,   190,   200,   165,
       4,   203,   167,    38,     5,   194,   206,   170,   280,   172,
      71,    39,     8,     7,    40,   145,   193,   238,     7,   202,
     296,   204,   208,   239,   241,   211,   227,    41,    42,   191,
     259,   192,    43,    44,   251,   194,   274,   278,   285,   254,
     291,   288,   194,   227,   292,   298,   258,   299,   215,   311,
     255,    45,   305,    46,   307,    80,    47,   185,   270,    49,
     218,    51,    52,   271,    53,   306,   173,   260,     4,   227,
     223,   248,     5,   286,   176,    55,   166,    56,    57,   289,
       8,   201,    59,    60,   297,     1,   281,   247,     2,   194,
     243,     0,   279,     0,     0,     3,   282,     4,     0,     0,
       0,     5,   287,   255,     0,   290,     0,     6,     7,     8,
       0,   294,   227,  -137,     0,     0,  -137,     0,  -137,     0,
       0,     0,   277,     0,     0,  -137,  -137,     0,     0,     0,
       0,  -137,     0,     0,     0,     0,     0,  -137,     0,   290,
     227,   227,   309,     0,     0,     0,     0,   227,   227,   161,
       0,     0,    45,     0,    46,     0,     0,    47,    48,     0,
      49,    50,    51,    52,     0,    53,     0,   304,     0,     4,
      54,    66,     0,     5,     0,     0,    55,     0,    56,    57,
     310,     8,    58,    59,    60,   312,    45,     0,    46,     0,
       0,    47,   216,   217,    49,   218,    51,    52,   219,    53,
     220,   221,     0,     4,   222,   223,     0,     5,   261,     0,
      55,     0,    56,    57,   224,     8,   225,    59,    60,   226,
      45,     0,    46,     0,     0,    47,   216,   217,    49,   218,
      51,    52,   219,    53,   220,   221,     0,     4,   222,   223,
       0,     5,   283,     0,    55,     0,    56,    57,   224,     8,
     225,    59,    60,   226,    45,     0,    46,     0,     0,    47,
     216,   217,    49,   218,    51,    52,   219,    53,   220,   221,
       0,     4,   222,   223,     0,     5,     0,     0,    55,     0,
      56,    57,   224,     8,   225,    59,    60,   226,    45,     0,
      46,     0,     0,    47,   216,   217,    49,   218,    51,    52,
     219,    53,   220,   302,     0,     4,   222,   223,     0,     5,
       0,     0,    55,     0,    56,    57,   224,     8,   225,    59,
      60,    45,     0,    46,    65,     0,    47,    48,     0,    49,
      50,    51,    52,     0,    53,     0,     0,     0,     4,    54,
      66,     0,     5,     0,    67,    55,     0,    56,    57,     0,
       8,    58,    59,    60,    45,     0,    46,    65,     0,    47,
      48,     0,    49,    50,    51,    52,     0,    53,     0,     0,
       0,     4,    54,    66,     0,     5,     0,   102,    55,     0,
      56,    57,     0,     8,    58,    59,    60,    45,     0,    46,
      65,     0,    47,    48,     0,    49,    50,    51,    52,     0,
      53,     0,     0,     0,     4,    54,    66,     0,     5,     0,
     214,    55,     0,    56,    57,     0,     8,    58,    59,    60,
      45,    75,    46,     0,     0,    47,    48,     0,    49,    50,
      51,    52,     0,    53,     0,     0,     0,     4,    54,    99,
       0,     5,     0,     0,    55,     0,    56,    57,     0,     8,
      58,    59,    60,    45,     0,    46,     0,     0,    47,    48,
       0,    49,    50,    51,    52,     0,    53,   131,     0,     0,
       4,    54,    66,     0,     5,     0,     0,    55,     0,    56,
      57,     0,     8,    58,    59,    60,    45,     0,    46,    65,
       0,    47,    48,     0,    49,    50,    51,    52,     0,    53,
       0,     0,     0,     4,    54,    66,     0,     5,     0,     0,
      55,     0,    56,    57,     0,     8,    58,    59,    60,    45,
       0,    46,     0,     0,    47,    48,     0,    49,    50,    51,
      52,     0,    53,     0,     0,     0,     4,    54,    66,     0,
       5,     0,     0,    55,   175,    56,    57,     0,     8,    58,
      59,    60,    45,     0,    46,     0,     0,    47,    48,     0,
      49,    50,    51,    52,     0,    53,     0,     0,     0,     4,
      54,    66,     0,     5,     0,     0,    55,     0,    56,    57,
       0,     8,    58,    59,    60,    45,     0,    46,     0,     0,
      47,    48,     0,    49,    50,    51,    52,     0,    53,     0,
       0,     0,     4,    54,     0,     0,     5,     0,     0,    55,
       0,    56,    57,     0,     8,    58,    59,    60
};

static const yytype_int16 yycheck[] =
{
       3,    99,    68,   177,     2,   177,     0,   100,    42,     0,
     199,     7,    15,   196,     7,     5,    31,    11,   107,   146,
      11,     6,   194,     8,    39,    77,     7,    31,    21,    10,
      34,    16,    22,   131,    19,    38,    39,    40,    41,   166,
      43,    44,    96,    95,     0,    21,   220,    32,   220,    29,
     139,   240,    37,    38,    34,   244,    90,    91,   151,    93,
     243,    29,   116,    97,   118,    68,    34,    65,   167,   121,
      29,   123,    75,    25,   126,    34,    42,   170,   130,   172,
      22,    84,    85,    86,    87,    88,    89,   187,     7,   263,
     190,   263,   191,   192,    17,     0,    23,   291,   292,    65,
      27,   104,   105,    21,    21,   299,    11,   173,    35,    14,
     113,    22,    21,    39,    21,     4,    21,   108,    23,   291,
     292,   124,    27,    10,    90,    91,   298,   299,    33,    34,
      35,    97,     5,   136,    29,   101,   127,   140,    23,    34,
     106,   239,    27,     5,    29,   148,   112,    29,   114,   115,
      35,   117,    34,   119,    22,   146,    21,    21,   161,   125,
      23,   164,   128,     8,    27,   159,    29,   133,    29,   135,
     173,    16,    35,    34,    19,   166,    10,   180,    34,     3,
     278,    21,    26,     5,    30,    28,   177,    32,    33,   155,
      26,   157,    37,    38,   197,   189,    25,     5,    29,   202,
       5,    29,   196,   194,    10,     5,   209,     5,   174,   307,
     204,     6,    26,     8,     5,    11,    11,   149,   221,    14,
      15,    16,    17,   226,    19,   296,   136,   215,    23,   220,
      25,   194,    27,   265,   140,    30,   127,    32,    33,   268,
      35,   161,    37,    38,   279,    11,   257,   193,    14,   243,
     189,    -1,   255,    -1,    -1,    21,   259,    23,    -1,    -1,
      -1,    27,   265,   257,    -1,   268,    -1,    33,    34,    35,
      -1,   274,   263,    12,    -1,    -1,    15,    -1,    17,    -1,
      -1,    -1,   248,    -1,    -1,    24,    25,    -1,    -1,    -1,
      -1,    30,    -1,    -1,    -1,    -1,    -1,    36,    -1,   302,
     291,   292,   305,    -1,    -1,    -1,    -1,   298,   299,     3,
      -1,    -1,     6,    -1,     8,    -1,    -1,    11,    12,    -1,
      14,    15,    16,    17,    -1,    19,    -1,   293,    -1,    23,
      24,    25,    -1,    27,    -1,    -1,    30,    -1,    32,    33,
     306,    35,    36,    37,    38,   311,     6,    -1,     8,    -1,
      -1,    11,    12,    13,    14,    15,    16,    17,    18,    19,
      20,    21,    -1,    23,    24,    25,    -1,    27,    28,    -1,
      30,    -1,    32,    33,    34,    35,    36,    37,    38,    39,
       6,    -1,     8,    -1,    -1,    11,    12,    13,    14,    15,
      16,    17,    18,    19,    20,    21,    -1,    23,    24,    25,
      -1,    27,    28,    -1,    30,    -1,    32,    33,    34,    35,
      36,    37,    38,    39,     6,    -1,     8,    -1,    -1,    11,
      12,    13,    14,    15,    16,    17,    18,    19,    20,    21,
      -1,    23,    24,    25,    -1,    27,    -1,    -1,    30,    -1,
      32,    33,    34,    35,    36,    37,    38,    39,     6,    -1,
       8,    -1,    -1,    11,    12,    13,    14,    15,    16,    17,
      18,    19,    20,    21,    -1,    23,    24,    25,    -1,    27,
      -1,    -1,    30,    -1,    32,    33,    34,    35,    36,    37,
      38,     6,    -1,     8,     9,    -1,    11,    12,    -1,    14,
      15,    16,    17,    -1,    19,    -1,    -1,    -1,    23,    24,
      25,    -1,    27,    -1,    29,    30,    -1,    32,    33,    -1,
      35,    36,    37,    38,     6,    -1,     8,     9,    -1,    11,
      12,    -1,    14,    15,    16,    17,    -1,    19,    -1,    -1,
      -1,    23,    24,    25,    -1,    27,    -1,    29,    30,    -1,
      32,    33,    -1,    35,    36,    37,    38,     6,    -1,     8,
       9,    -1,    11,    12,    -1,    14,    15,    16,    17,    -1,
      19,    -1,    -1,    -1,    23,    24,    25,    -1,    27,    -1,
      29,    30,    -1,    32,    33,    -1,    35,    36,    37,    38,
       6,     7,     8,    -1,    -1,    11,    12,    -1,    14,    15,
      16,    17,    -1,    19,    -1,    -1,    -1,    23,    24,    25,
      -1,    27,    -1,    -1,    30,    -1,    32,    33,    -1,    35,
      36,    37,    38,     6,    -1,     8,    -1,    -1,    11,    12,
      -1,    14,    15,    16,    17,    -1,    19,    20,    -1,    -1,
      23,    24,    25,    -1,    27,    -1,    -1,    30,    -1,    32,
      33,    -1,    35,    36,    37,    38,     6,    -1,     8,     9,
      -1,    11,    12,    -1,    14,    15,    16,    17,    -1,    19,
      -1,    -1,    -1,    23,    24,    25,    -1,    27,    -1,    -1,
      30,    -1,    32,    33,    -1,    35,    36,    37,    38,     6,
      -1,     8,    -1,    -1,    11,    12,    -1,    14,    15,    16,
      17,    -1,    19,    -1,    -1,    -1,    23,    24,    25,    -1,
      27,    -1,    -1,    30,    31,    32,    33,    -1,    35,    36,
      37,    38,     6,    -1,     8,    -1,    -1,    11,    12,    -1,
      14,    15,    16,    17,    -1,    19,    -1,    -1,    -1,    23,
      24,    25,    -1,    27,    -1,    -1,    30,    -1,    32,    33,
      -1,    35,    36,    37,    38,     6,    -1,     8,    -1,    -1,
      11,    12,    -1,    14,    15,    16,    17,    -1,    19,    -1,
      -1,    -1,    23,    24,    -1,    -1,    27,    -1,    -1,    30,
      -1,    32,    33,    -1,    35,    36,    37,    38
};

/* YYSTOS[STATE-NUM] -- The symbol kind of the accessing symbol of
   state STATE-NUM.  */
static const yytype_int8 yystos[] =
{
       0,    11,    14,    21,    23,    27,    33,    34,    35,    41,
      42,    43,    44,    45,    46,    47,    85,    89,    90,    94,
      95,    96,    97,    98,   108,   111,   112,   115,   116,   119,
     120,   121,   122,   123,   124,   125,   126,   127,     8,    16,
      19,    32,    33,    37,    38,     6,     8,    11,    12,    14,
      15,    16,    17,    19,    24,    30,    32,    33,    36,    37,
      38,    47,    81,    82,    86,     9,    25,    29,    53,    54,
      57,    80,    82,    83,    84,     7,    77,    78,    79,     0,
      44,    48,    80,     6,     8,    16,    19,    32,    37,    38,
      80,    80,    80,    80,    77,    78,    80,    80,    25,    25,
      77,    82,    29,    54,     5,    22,    58,    80,    21,    91,
      79,    22,    49,     7,    80,    80,    80,    80,    80,    80,
      77,    78,    77,    78,    17,    99,    78,    21,    99,    77,
      78,    20,    80,    87,    88,    87,    21,    55,    77,    80,
      59,    60,    80,    77,    58,    47,    92,    93,    39,    50,
      51,    77,    80,    77,    77,    99,    77,    99,    77,    21,
      21,     3,    80,   100,   101,    77,    92,    77,    10,    87,
      77,     4,    77,    53,    58,    31,    60,     5,    55,    56,
       5,    29,    93,    80,    31,    51,    55,    22,   104,    21,
      21,    77,    77,    10,    96,   113,   114,    96,   102,   103,
      80,   100,     3,    80,    21,   106,    29,   106,    26,   109,
     110,    28,    55,    55,    29,    77,    12,    13,    15,    18,
      20,    21,    24,    25,    34,    36,    39,    47,    61,    62,
      63,    64,    65,    67,    68,    69,    73,    81,    80,     5,
     103,    30,   117,   114,   103,   106,   106,   110,    67,    29,
     113,    80,    29,   102,    80,    96,   105,   107,    80,    26,
      56,    28,    62,    66,    70,    71,    72,    74,    75,    76,
      80,    80,    87,    31,    25,    29,    29,    77,     5,    80,
      29,   105,    80,    28,    62,    29,    72,    80,    29,    76,
      80,     5,    10,    52,    80,   118,    87,   104,     5,     5,
      61,    62,    21,    61,    77,    26,    52,     5,    61,    80,
      77,    87,    77
};

/* YYR1[RULE-NUM] -- Symbol kind of the left-hand side of rule RULE-NUM.  */
static const yytype_int8 yyr1[] =
{
       0,    40,    41,    42,    43,    43,    44,    44,    44,    45,
      45,    46,    46,    46,    47,    47,    47,    48,    48,    49,
      49,    50,    50,    51,    52,    52,    53,    53,    54,    54,
      54,    55,    56,    56,    57,    57,    58,    58,    59,    59,
      60,    61,    61,    61,    61,    61,    61,    61,    61,    61,
      62,    62,    62,    63,    64,    65,    65,    66,    66,    67,
      67,    67,    67,    68,    69,    70,    70,    71,    71,    72,
      73,    74,    74,    75,    75,    76,    77,    77,    78,    78,
      79,    80,    80,    81,    81,    81,    81,    81,    81,    81,
      81,    81,    81,    81,    81,    82,    82,    82,    82,    82,
      82,    83,    84,    84,    85,    86,    86,    87,    87,    88,
      88,    89,    89,    89,    90,    91,    91,    92,    92,    93,
      94,    94,    94,    94,    94,    94,    95,    96,    96,    97,
      98,    99,    99,    99,    99,   100,   100,   101,   101,   102,
     103,   103,   104,   104,   105,   106,   106,   107,   107,   107,
     108,   109,   109,   110,   110,   111,   112,   113,   114,   114,
     115,   116,   117,   117,   118,   118,   119,   119,   120,   120,
     121,   121,   121,   121,   121,   121,   122,   123,   124,   125,
     125,   126,   126,   127,   127
};

/* YYR2[RULE-NUM] -- Number of symbols on the right-hand side of rule RULE-NUM.  */
static const yytype_int8 yyr2[] =
{
       0,     2,     1,     1,     1,     2,     1,     1,     1,     1,
       1,     5,     3,     2,     1,     1,     1,     0,     1,     0,
       3,     1,     2,     6,     0,     2,     1,     2,     1,     1,
       1,     3,     0,     1,     6,     4,     0,     3,     1,     2,
       3,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     2,     2,     3,     1,     2,     1,
       1,     1,     1,     1,     3,     0,     1,     1,     2,     3,
       3,     0,     1,     1,     2,     3,     0,     1,     1,     2,
       3,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     3,     5,     3,     6,     0,     1,     1,     2,     1,
       3,     1,     1,     1,     3,     0,     3,     1,     2,     3,
       1,     1,     1,     1,     1,     1,     1,     0,     1,     4,
       6,     0,     3,     2,     2,     1,     3,     1,     2,     6,
       1,     2,     0,     3,     6,     0,     3,     0,     1,     2,
       6,     0,     1,     2,     3,     6,     7,     3,     1,     2,
       7,     8,     0,     1,     1,     3,     1,     1,     6,     3,
       1,     1,     1,     1,     1,     1,     4,     6,     6,     6,
       4,     7,     4,     7,     4
};


enum { YYENOMEM = -2 };

#define yyerrok         (yyerrstatus = 0)
#define yyclearin       (yychar = YYEMPTY)

#define YYACCEPT        goto yyacceptlab
#define YYABORT         goto yyabortlab
#define YYERROR         goto yyerrorlab
#define YYNOMEM         goto yyexhaustedlab


#define YYRECOVERING()  (!!yyerrstatus)

#define YYBACKUP(Token, Value)                                    \
  do                                                              \
    if (yychar == YYEMPTY)                                        \
      {                                                           \
        yychar = (Token);                                         \
        yylval = (Value);                                         \
        YYPOPSTACK (yylen);                                       \
        yystate = *yyssp;                                         \
        goto yybackup;                                            \
      }                                                           \
    else                                                          \
      {                                                           \
        yyerror (parser, filename, YY_("syntax error: cannot back up")); \
        YYERROR;                                                  \
      }                                                           \
  while (0)

/* Backward compatibility with an undocumented macro.
   Use YYerror or YYUNDEF. */
#define YYERRCODE YYUNDEF


/* Enable debugging if requested.  */
#if YYDEBUG

# ifndef YYFPRINTF
#  include <stdio.h> /* INFRINGES ON USER NAME SPACE */
#  define YYFPRINTF fprintf
# endif

# define YYDPRINTF(Args)                        \
do {                                            \
  if (yydebug)                                  \
    YYFPRINTF Args;                             \
} while (0)




# define YY_SYMBOL_PRINT(Title, Kind, Value, Location)                    \
do {                                                                      \
  if (yydebug)                                                            \
    {                                                                     \
      YYFPRINTF (stderr, "%s ", Title);                                   \
      yy_symbol_print (stderr,                                            \
                  Kind, Value, parser, filename); \
      YYFPRINTF (stderr, "\n");                                           \
    }                                                                     \
} while (0)


/*-----------------------------------.
| Print this symbol's value on YYO.  |
`-----------------------------------*/

static void
yy_symbol_value_print (FILE *yyo,
                       yysymbol_kind_t yykind, YYSTYPE const * const yyvaluep, VALUE parser, VALUE filename)
{
  FILE *yyoutput = yyo;
  YY_USE (yyoutput);
  YY_USE (parser);
  YY_USE (filename);
  if (!yyvaluep)
    return;
  YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
  YY_USE (yykind);
  YY_IGNORE_MAYBE_UNINITIALIZED_END
}


/*---------------------------.
| Print this symbol on YYO.  |
`---------------------------*/

static void
yy_symbol_print (FILE *yyo,
                 yysymbol_kind_t yykind, YYSTYPE const * const yyvaluep, VALUE parser, VALUE filename)
{
  YYFPRINTF (yyo, "%s %s (",
             yykind < YYNTOKENS ? "token" : "nterm", yysymbol_name (yykind));

  yy_symbol_value_print (yyo, yykind, yyvaluep, parser, filename);
  YYFPRINTF (yyo, ")");
}

/*------------------------------------------------------------------.
| yy_stack_print -- Print the state stack from its BOTTOM up to its |
| TOP (included).                                                   |
`------------------------------------------------------------------*/

static void
yy_stack_print (yy_state_t *yybottom, yy_state_t *yytop)
{
  YYFPRINTF (stderr, "Stack now");
  for (; yybottom <= yytop; yybottom++)
    {
      int yybot = *yybottom;
      YYFPRINTF (stderr, " %d", yybot);
    }
  YYFPRINTF (stderr, "\n");
}

# define YY_STACK_PRINT(Bottom, Top)                            \
do {                                                            \
  if (yydebug)                                                  \
    yy_stack_print ((Bottom), (Top));                           \
} while (0)


/*------------------------------------------------.
| Report that the YYRULE is going to be reduced.  |
`------------------------------------------------*/

static void
yy_reduce_print (yy_state_t *yyssp, YYSTYPE *yyvsp,
                 int yyrule, VALUE parser, VALUE filename)
{
  int yylno = yyrline[yyrule];
  int yynrhs = yyr2[yyrule];
  int yyi;
  YYFPRINTF (stderr, "Reducing stack by rule %d (line %d):\n",
             yyrule - 1, yylno);
  /* The symbols being reduced.  */
  for (yyi = 0; yyi < yynrhs; yyi++)
    {
      YYFPRINTF (stderr, "   $%d = ", yyi + 1);
      yy_symbol_print (stderr,
                       YY_ACCESSING_SYMBOL (+yyssp[yyi + 1 - yynrhs]),
                       &yyvsp[(yyi + 1) - (yynrhs)], parser, filename);
      YYFPRINTF (stderr, "\n");
    }
}

# define YY_REDUCE_PRINT(Rule)          \
do {                                    \
  if (yydebug)                          \
    yy_reduce_print (yyssp, yyvsp, Rule, parser, filename); \
} while (0)

/* Nonzero means print parse trace.  It is left uninitialized so that
   multiple parsers can coexist.  */
int yydebug;
#else /* !YYDEBUG */
# define YYDPRINTF(Args) ((void) 0)
# define YY_SYMBOL_PRINT(Title, Kind, Value, Location)
# define YY_STACK_PRINT(Bottom, Top)
# define YY_REDUCE_PRINT(Rule)
#endif /* !YYDEBUG */


/* YYINITDEPTH -- initial size of the parser's stacks.  */
#ifndef YYINITDEPTH
# define YYINITDEPTH 200
#endif

/* YYMAXDEPTH -- maximum size the stacks can grow to (effective only
   if the built-in stack extension method is used).

   Do not make this value too large; the results are undefined if
   YYSTACK_ALLOC_MAXIMUM < YYSTACK_BYTES (YYMAXDEPTH)
   evaluated with infinite-precision integer arithmetic.  */

#ifndef YYMAXDEPTH
# define YYMAXDEPTH 10000
#endif


/* Context of a parse error.  */
typedef struct
{
  yy_state_t *yyssp;
  yysymbol_kind_t yytoken;
} yypcontext_t;

/* Put in YYARG at most YYARGN of the expected tokens given the
   current YYCTX, and return the number of tokens stored in YYARG.  If
   YYARG is null, return the number of expected tokens (guaranteed to
   be less than YYNTOKENS).  Return YYENOMEM on memory exhaustion.
   Return 0 if there are more than YYARGN expected tokens, yet fill
   YYARG up to YYARGN. */
static int
yypcontext_expected_tokens (const yypcontext_t *yyctx,
                            yysymbol_kind_t yyarg[], int yyargn)
{
  /* Actual size of YYARG. */
  int yycount = 0;
  int yyn = yypact[+*yyctx->yyssp];
  if (!yypact_value_is_default (yyn))
    {
      /* Start YYX at -YYN if negative to avoid negative indexes in
         YYCHECK.  In other words, skip the first -YYN actions for
         this state because they are default actions.  */
      int yyxbegin = yyn < 0 ? -yyn : 0;
      /* Stay within bounds of both yycheck and yytname.  */
      int yychecklim = YYLAST - yyn + 1;
      int yyxend = yychecklim < YYNTOKENS ? yychecklim : YYNTOKENS;
      int yyx;
      for (yyx = yyxbegin; yyx < yyxend; ++yyx)
        if (yycheck[yyx + yyn] == yyx && yyx != YYSYMBOL_YYerror
            && !yytable_value_is_error (yytable[yyx + yyn]))
          {
            if (!yyarg)
              ++yycount;
            else if (yycount == yyargn)
              return 0;
            else
              yyarg[yycount++] = YY_CAST (yysymbol_kind_t, yyx);
          }
    }
  if (yyarg && yycount == 0 && 0 < yyargn)
    yyarg[0] = YYSYMBOL_YYEMPTY;
  return yycount;
}




#ifndef yystrlen
# if defined __GLIBC__ && defined _STRING_H
#  define yystrlen(S) (YY_CAST (YYPTRDIFF_T, strlen (S)))
# else
/* Return the length of YYSTR.  */
static YYPTRDIFF_T
yystrlen (const char *yystr)
{
  YYPTRDIFF_T yylen;
  for (yylen = 0; yystr[yylen]; yylen++)
    continue;
  return yylen;
}
# endif
#endif

#ifndef yystpcpy
# if defined __GLIBC__ && defined _STRING_H && defined _GNU_SOURCE
#  define yystpcpy stpcpy
# else
/* Copy YYSRC to YYDEST, returning the address of the terminating '\0' in
   YYDEST.  */
static char *
yystpcpy (char *yydest, const char *yysrc)
{
  char *yyd = yydest;
  const char *yys = yysrc;

  while ((*yyd++ = *yys++) != '\0')
    continue;

  return yyd - 1;
}
# endif
#endif



static int
yy_syntax_error_arguments (const yypcontext_t *yyctx,
                           yysymbol_kind_t yyarg[], int yyargn)
{
  /* Actual size of YYARG. */
  int yycount = 0;
  /* There are many possibilities here to consider:
     - If this state is a consistent state with a default action, then
       the only way this function was invoked is if the default action
       is an error action.  In that case, don't check for expected
       tokens because there are none.
     - The only way there can be no lookahead present (in yychar) is if
       this state is a consistent state with a default action.  Thus,
       detecting the absence of a lookahead is sufficient to determine
       that there is no unexpected or expected token to report.  In that
       case, just report a simple "syntax error".
     - Don't assume there isn't a lookahead just because this state is a
       consistent state with a default action.  There might have been a
       previous inconsistent state, consistent state with a non-default
       action, or user semantic action that manipulated yychar.
     - Of course, the expected token list depends on states to have
       correct lookahead information, and it depends on the parser not
       to perform extra reductions after fetching a lookahead from the
       scanner and before detecting a syntax error.  Thus, state merging
       (from LALR or IELR) and default reductions corrupt the expected
       token list.  However, the list is correct for canonical LR with
       one exception: it will still contain any token that will not be
       accepted due to an error action in a later state.
  */
  if (yyctx->yytoken != YYSYMBOL_YYEMPTY)
    {
      int yyn;
      if (yyarg)
        yyarg[yycount] = yyctx->yytoken;
      ++yycount;
      yyn = yypcontext_expected_tokens (yyctx,
                                        yyarg ? yyarg + 1 : yyarg, yyargn - 1);
      if (yyn == YYENOMEM)
        return YYENOMEM;
      else
        yycount += yyn;
    }
  return yycount;
}

/* Copy into *YYMSG, which is of size *YYMSG_ALLOC, an error message
   about the unexpected token YYTOKEN for the state stack whose top is
   YYSSP.

   Return 0 if *YYMSG was successfully written.  Return -1 if *YYMSG is
   not large enough to hold the message.  In that case, also set
   *YYMSG_ALLOC to the required number of bytes.  Return YYENOMEM if the
   required number of bytes is too large to store.  */
static int
yysyntax_error (YYPTRDIFF_T *yymsg_alloc, char **yymsg,
                const yypcontext_t *yyctx)
{
  enum { YYARGS_MAX = 5 };
  /* Internationalized format string. */
  const char *yyformat = YY_NULLPTR;
  /* Arguments of yyformat: reported tokens (one for the "unexpected",
     one per "expected"). */
  yysymbol_kind_t yyarg[YYARGS_MAX];
  /* Cumulated lengths of YYARG.  */
  YYPTRDIFF_T yysize = 0;

  /* Actual size of YYARG. */
  int yycount = yy_syntax_error_arguments (yyctx, yyarg, YYARGS_MAX);
  if (yycount == YYENOMEM)
    return YYENOMEM;

  switch (yycount)
    {
#define YYCASE_(N, S)                       \
      case N:                               \
        yyformat = S;                       \
        break
    default: /* Avoid compiler warnings. */
      YYCASE_(0, YY_("syntax error"));
      YYCASE_(1, YY_("syntax error, unexpected %s"));
      YYCASE_(2, YY_("syntax error, unexpected %s, expecting %s"));
      YYCASE_(3, YY_("syntax error, unexpected %s, expecting %s or %s"));
      YYCASE_(4, YY_("syntax error, unexpected %s, expecting %s or %s or %s"));
      YYCASE_(5, YY_("syntax error, unexpected %s, expecting %s or %s or %s or %s"));
#undef YYCASE_
    }

  /* Compute error message size.  Don't count the "%s"s, but reserve
     room for the terminator.  */
  yysize = yystrlen (yyformat) - 2 * yycount + 1;
  {
    int yyi;
    for (yyi = 0; yyi < yycount; ++yyi)
      {
        YYPTRDIFF_T yysize1
          = yysize + yystrlen (yysymbol_name (yyarg[yyi]));
        if (yysize <= yysize1 && yysize1 <= YYSTACK_ALLOC_MAXIMUM)
          yysize = yysize1;
        else
          return YYENOMEM;
      }
  }

  if (*yymsg_alloc < yysize)
    {
      *yymsg_alloc = 2 * yysize;
      if (! (yysize <= *yymsg_alloc
             && *yymsg_alloc <= YYSTACK_ALLOC_MAXIMUM))
        *yymsg_alloc = YYSTACK_ALLOC_MAXIMUM;
      return -1;
    }

  /* Avoid sprintf, as that infringes on the user's name space.
     Don't have undefined behavior even if the translation
     produced a string with the wrong number of "%s"s.  */
  {
    char *yyp = *yymsg;
    int yyi = 0;
    while ((*yyp = *yyformat) != '\0')
      if (*yyp == '%' && yyformat[1] == 's' && yyi < yycount)
        {
          yyp = yystpcpy (yyp, yysymbol_name (yyarg[yyi++]));
          yyformat += 2;
        }
      else
        {
          ++yyp;
          ++yyformat;
        }
  }
  return 0;
}


/*-----------------------------------------------.
| Release the memory associated to this symbol.  |
`-----------------------------------------------*/

static void
yydestruct (const char *yymsg,
            yysymbol_kind_t yykind, YYSTYPE *yyvaluep, VALUE parser, VALUE filename)
{
  YY_USE (yyvaluep);
  YY_USE (parser);
  YY_USE (filename);
  if (!yymsg)
    yymsg = "Deleting";
  YY_SYMBOL_PRINT (yymsg, yykind, yyvaluep, yylocationp);

  YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
  YY_USE (yykind);
  YY_IGNORE_MAYBE_UNINITIALIZED_END
}






/*----------.
| yyparse.  |
`----------*/

int
yyparse (VALUE parser, VALUE filename)
{
/* Lookahead token kind.  */
int yychar;


/* The semantic value of the lookahead symbol.  */
/* Default value used for initialization, for pacifying older GCCs
   or non-GCC compilers.  */
YY_INITIAL_VALUE (static YYSTYPE yyval_default;)
YYSTYPE yylval YY_INITIAL_VALUE (= yyval_default);

    /* Number of syntax errors so far.  */
    int yynerrs = 0;

    yy_state_fast_t yystate = 0;
    /* Number of tokens to shift before error messages enabled.  */
    int yyerrstatus = 0;

    /* Refer to the stacks through separate pointers, to allow yyoverflow
       to reallocate them elsewhere.  */

    /* Their size.  */
    YYPTRDIFF_T yystacksize = YYINITDEPTH;

    /* The state stack: array, bottom, top.  */
    yy_state_t yyssa[YYINITDEPTH];
    yy_state_t *yyss = yyssa;
    yy_state_t *yyssp = yyss;

    /* The semantic value stack: array, bottom, top.  */
    YYSTYPE yyvsa[YYINITDEPTH];
    YYSTYPE *yyvs = yyvsa;
    YYSTYPE *yyvsp = yyvs;

  int yyn;
  /* The return value of yyparse.  */
  int yyresult;
  /* Lookahead symbol kind.  */
  yysymbol_kind_t yytoken = YYSYMBOL_YYEMPTY;
  /* The variables used to return semantic value and location from the
     action routines.  */
  YYSTYPE yyval;

  /* Buffer for error messages, and its allocated size.  */
  char yymsgbuf[128];
  char *yymsg = yymsgbuf;
  YYPTRDIFF_T yymsg_alloc = sizeof yymsgbuf;

#define YYPOPSTACK(N)   (yyvsp -= (N), yyssp -= (N))

  /* The number of symbols on the RHS of the reduced rule.
     Keep to zero when no symbol should be popped.  */
  int yylen = 0;

  YYDPRINTF ((stderr, "Starting parse\n"));

  yychar = YYEMPTY; /* Cause a token to be read.  */

  goto yysetstate;


/*------------------------------------------------------------.
| yynewstate -- push a new state, which is found in yystate.  |
`------------------------------------------------------------*/
yynewstate:
  /* In all cases, when you get here, the value and location stacks
     have just been pushed.  So pushing a state here evens the stacks.  */
  yyssp++;


/*--------------------------------------------------------------------.
| yysetstate -- set current state (the top of the stack) to yystate.  |
`--------------------------------------------------------------------*/
yysetstate:
  YYDPRINTF ((stderr, "Entering state %d\n", yystate));
  YY_ASSERT (0 <= yystate && yystate < YYNSTATES);
  YY_IGNORE_USELESS_CAST_BEGIN
  *yyssp = YY_CAST (yy_state_t, yystate);
  YY_IGNORE_USELESS_CAST_END
  YY_STACK_PRINT (yyss, yyssp);

  if (yyss + yystacksize - 1 <= yyssp)
#if !defined yyoverflow && !defined YYSTACK_RELOCATE
    YYNOMEM;
#else
    {
      /* Get the current used size of the three stacks, in elements.  */
      YYPTRDIFF_T yysize = yyssp - yyss + 1;

# if defined yyoverflow
      {
        /* Give user a chance to reallocate the stack.  Use copies of
           these so that the &'s don't force the real ones into
           memory.  */
        yy_state_t *yyss1 = yyss;
        YYSTYPE *yyvs1 = yyvs;

        /* Each stack pointer address is followed by the size of the
           data in use in that stack, in bytes.  This used to be a
           conditional around just the two extra args, but that might
           be undefined if yyoverflow is a macro.  */
        yyoverflow (YY_("memory exhausted"),
                    &yyss1, yysize * YYSIZEOF (*yyssp),
                    &yyvs1, yysize * YYSIZEOF (*yyvsp),
                    &yystacksize);
        yyss = yyss1;
        yyvs = yyvs1;
      }
# else /* defined YYSTACK_RELOCATE */
      /* Extend the stack our own way.  */
      if (YYMAXDEPTH <= yystacksize)
        YYNOMEM;
      yystacksize *= 2;
      if (YYMAXDEPTH < yystacksize)
        yystacksize = YYMAXDEPTH;

      {
        yy_state_t *yyss1 = yyss;
        union yyalloc *yyptr =
          YY_CAST (union yyalloc *,
                   YYSTACK_ALLOC (YY_CAST (YYSIZE_T, YYSTACK_BYTES (yystacksize))));
        if (! yyptr)
          YYNOMEM;
        YYSTACK_RELOCATE (yyss_alloc, yyss);
        YYSTACK_RELOCATE (yyvs_alloc, yyvs);
#  undef YYSTACK_RELOCATE
        if (yyss1 != yyssa)
          YYSTACK_FREE (yyss1);
      }
# endif

      yyssp = yyss + yysize - 1;
      yyvsp = yyvs + yysize - 1;

      YY_IGNORE_USELESS_CAST_BEGIN
      YYDPRINTF ((stderr, "Stack size increased to %ld\n",
                  YY_CAST (long, yystacksize)));
      YY_IGNORE_USELESS_CAST_END

      if (yyss + yystacksize - 1 <= yyssp)
        YYABORT;
    }
#endif /* !defined yyoverflow && !defined YYSTACK_RELOCATE */


  if (yystate == YYFINAL)
    YYACCEPT;

  goto yybackup;


/*-----------.
| yybackup.  |
`-----------*/
yybackup:
  /* Do appropriate processing given the current state.  Read a
     lookahead token if we need one and don't already have one.  */

  /* First try to decide what to do without reference to lookahead token.  */
  yyn = yypact[yystate];
  if (yypact_value_is_default (yyn))
    goto yydefault;

  /* Not known => get a lookahead token if don't already have one.  */

  /* YYCHAR is either empty, or end-of-input, or a valid lookahead.  */
  if (yychar == YYEMPTY)
    {
      YYDPRINTF ((stderr, "Reading a token\n"));
      yychar = yylex (&yylval, parser, filename);
    }

  if (yychar <= YYEOF)
    {
      yychar = YYEOF;
      yytoken = YYSYMBOL_YYEOF;
      YYDPRINTF ((stderr, "Now at end of input.\n"));
    }
  else if (yychar == YYerror)
    {
      /* The scanner already issued an error message, process directly
         to error recovery.  But do not keep the error token as
         lookahead, it is too special and may lead us to an endless
         loop in error recovery. */
      yychar = YYUNDEF;
      yytoken = YYSYMBOL_YYerror;
      goto yyerrlab1;
    }
  else
    {
      yytoken = YYTRANSLATE (yychar);
      YY_SYMBOL_PRINT ("Next token is", yytoken, &yylval, &yylloc);
    }

  /* If the proper action on seeing token YYTOKEN is to reduce or to
     detect an error, take that action.  */
  yyn += yytoken;
  if (yyn < 0 || YYLAST < yyn || yycheck[yyn] != yytoken)
    goto yydefault;
  yyn = yytable[yyn];
  if (yyn <= 0)
    {
      if (yytable_value_is_error (yyn))
        goto yyerrlab;
      yyn = -yyn;
      goto yyreduce;
    }

  /* Count tokens shifted since error; after three, turn off error
     status.  */
  if (yyerrstatus)
    yyerrstatus--;

  /* Shift the lookahead token.  */
  YY_SYMBOL_PRINT ("Shifting", yytoken, &yylval, &yylloc);
  yystate = yyn;
  YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
  *++yyvsp = yylval;
  YY_IGNORE_MAYBE_UNINITIALIZED_END

  /* Discard the shifted token.  */
  yychar = YYEMPTY;
  goto yynewstate;


/*-----------------------------------------------------------.
| yydefault -- do the default action for the current state.  |
`-----------------------------------------------------------*/
yydefault:
  yyn = yydefact[yystate];
  if (yyn == 0)
    goto yyerrlab;
  goto yyreduce;


/*-----------------------------.
| yyreduce -- do a reduction.  |
`-----------------------------*/
yyreduce:
  /* yyn is the number of a rule to reduce with.  */
  yylen = yyr2[yyn];

  /* If YYLEN is nonzero, implement the default value of the action:
     '$$ = $1'.

     Otherwise, the following line sets YYVAL to garbage.
     This behavior is undocumented and Bison
     users should not rely upon it.  Assigning to YYVAL
     unconditionally makes the parser a bit smaller, and it avoids a
     GCC warning that YYVAL may be used uninitialized.  */
  yyval = yyvsp[1-yylen];


  YY_REDUCE_PRINT (yyn);
  switch (yyn)
    {
  case 2: /* start: document  */
#line 103 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                  { rb_ivar_set(parser, rb_intern("@result"), yyvsp[0]); }
#line 1917 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 3: /* document: definitions_list  */
#line 105 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                             {
    VALUE position_source = rb_ary_entry(yyvsp[0], 0);
    VALUE line, col;
    if (RB_TEST(position_source)) {
      line = rb_funcall(position_source, rb_intern("line"), 0);
      col = rb_funcall(position_source, rb_intern("col"), 0);
    } else {
      line = INT2FIX(1);
      col = INT2FIX(1);
    }
    yyval = MAKE_AST_NODE(Document, 3, line, col, yyvsp[0]);
  }
#line 1934 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 4: /* definitions_list: definition  */
#line 119 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                  { yyval = rb_ary_new_from_args(1, yyvsp[0]); }
#line 1940 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 5: /* definitions_list: definitions_list definition  */
#line 120 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                  { rb_ary_push(yyval, yyvsp[0]); }
#line 1946 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 11: /* operation_definition: operation_type operation_name_opt variable_definitions_opt directives_list_opt selection_set  */
#line 132 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                                                                   {
        yyval = MAKE_AST_NODE(OperationDefinition, 7,
          rb_ary_entry(yyvsp[-4], 1),
          rb_ary_entry(yyvsp[-4], 2),
          rb_ary_entry(yyvsp[-4], 3),
          (RB_TEST(yyvsp[-3]) ? rb_ary_entry(yyvsp[-3], 3) : Qnil),
          yyvsp[-2],
          yyvsp[-1],
          yyvsp[0]
        );
      }
#line 1962 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 12: /* operation_definition: LCURLY selection_list RCURLY  */
#line 143 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                   {
        yyval = MAKE_AST_NODE(OperationDefinition, 7,
          rb_ary_entry(yyvsp[-2], 1),
          rb_ary_entry(yyvsp[-2], 2),
          r_string_query,
          Qnil,
          GraphQL_Language_Nodes_NONE,
          GraphQL_Language_Nodes_NONE,
          yyvsp[-1]
        );
      }
#line 1978 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 13: /* operation_definition: LCURLY RCURLY  */
#line 154 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                    {
        yyval = MAKE_AST_NODE(OperationDefinition, 7,
          rb_ary_entry(yyvsp[-1], 1),
          rb_ary_entry(yyvsp[-1], 2),
          r_string_query,
          Qnil,
          GraphQL_Language_Nodes_NONE,
          GraphQL_Language_Nodes_NONE,
          GraphQL_Language_Nodes_NONE
        );
      }
#line 1994 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 17: /* operation_name_opt: %empty  */
#line 172 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                 { yyval = Qnil; }
#line 2000 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 19: /* variable_definitions_opt: %empty  */
#line 176 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                              { yyval = GraphQL_Language_Nodes_NONE; }
#line 2006 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 20: /* variable_definitions_opt: LPAREN variable_definitions_list RPAREN  */
#line 177 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                              { yyval = yyvsp[-1]; }
#line 2012 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 21: /* variable_definitions_list: variable_definition  */
#line 180 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                    { yyval = rb_ary_new_from_args(1, yyvsp[0]); }
#line 2018 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 22: /* variable_definitions_list: variable_definitions_list variable_definition  */
#line 181 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                    { rb_ary_push(yyval, yyvsp[0]); }
#line 2024 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 23: /* variable_definition: VAR_SIGN name COLON type default_value_opt directives_list_opt  */
#line 184 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                                     {
        yyval = MAKE_AST_NODE(VariableDefinition, 6,
          rb_ary_entry(yyvsp[-5], 1),
          rb_ary_entry(yyvsp[-5], 2),
          rb_ary_entry(yyvsp[-4], 3),
          yyvsp[-2],
          yyvsp[-1],
          yyvsp[0]
        );
      }
#line 2039 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 24: /* default_value_opt: %empty  */
#line 196 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                            { yyval = Qnil; }
#line 2045 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 25: /* default_value_opt: EQUALS literal_value  */
#line 197 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                            { yyval = yyvsp[0]; }
#line 2051 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 26: /* selection_list: selection  */
#line 200 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                { yyval = rb_ary_new_from_args(1, yyvsp[0]); }
#line 2057 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 27: /* selection_list: selection_list selection  */
#line 201 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                { rb_ary_push(yyval, yyvsp[0]); }
#line 2063 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 31: /* selection_set: LCURLY selection_list RCURLY  */
#line 209 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                   { yyval = yyvsp[-1]; }
#line 2069 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 32: /* selection_set_opt: %empty  */
#line 212 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                    { yyval = rb_ary_new(); }
#line 2075 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 34: /* field: name COLON name arguments_opt directives_list_opt selection_set_opt  */
#line 216 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                                        {
      yyval = MAKE_AST_NODE(Field, 7,
        rb_ary_entry(yyvsp[-5], 1),
        rb_ary_entry(yyvsp[-5], 2),
        rb_ary_entry(yyvsp[-5], 3), // alias
        rb_ary_entry(yyvsp[-3], 3), // name
        yyvsp[-2], // args
        yyvsp[-1], // directives
        yyvsp[0] // subselections
      );
    }
#line 2091 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 35: /* field: name arguments_opt directives_list_opt selection_set_opt  */
#line 227 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                               {
      yyval = MAKE_AST_NODE(Field, 7,
        rb_ary_entry(yyvsp[-3], 1),
        rb_ary_entry(yyvsp[-3], 2),
        Qnil, // alias
        rb_ary_entry(yyvsp[-3], 3), // name
        yyvsp[-2], // args
        yyvsp[-1], // directives
        yyvsp[0] // subselections
      );
    }
#line 2107 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 36: /* arguments_opt: %empty  */
#line 240 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                    { yyval = GraphQL_Language_Nodes_NONE; }
#line 2113 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 37: /* arguments_opt: LPAREN arguments_list RPAREN  */
#line 241 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                    { yyval = yyvsp[-1]; }
#line 2119 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 38: /* arguments_list: argument  */
#line 244 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                              { yyval = rb_ary_new_from_args(1, yyvsp[0]); }
#line 2125 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 39: /* arguments_list: arguments_list argument  */
#line 245 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                              { rb_ary_push(yyval, yyvsp[0]); }
#line 2131 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 40: /* argument: name COLON input_value  */
#line 248 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                             {
        yyval = MAKE_AST_NODE(Argument, 4,
          rb_ary_entry(yyvsp[-2], 1),
          rb_ary_entry(yyvsp[-2], 2),
          rb_ary_entry(yyvsp[-2], 3),
          yyvsp[0]
        );
      }
#line 2144 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 41: /* literal_value: FLOAT  */
#line 258 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                  { yyval = rb_funcall(rb_ary_entry(yyvsp[0], 3), rb_intern("to_f"), 0); }
#line 2150 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 42: /* literal_value: INT  */
#line 259 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                  { yyval = rb_funcall(rb_ary_entry(yyvsp[0], 3), rb_intern("to_i"), 0); }
#line 2156 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 43: /* literal_value: STRING  */
#line 260 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                  { yyval = rb_ary_entry(yyvsp[0], 3); }
#line 2162 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 44: /* literal_value: TRUE_LITERAL  */
#line 261 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                          { yyval = Qtrue; }
#line 2168 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 45: /* literal_value: FALSE_LITERAL  */
#line 262 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                          { yyval = Qfalse; }
#line 2174 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 53: /* null_value: NULL_LITERAL  */
#line 273 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                           {
    yyval = MAKE_AST_NODE(NullValue, 3,
      rb_ary_entry(yyvsp[0], 1),
      rb_ary_entry(yyvsp[0], 2),
      rb_ary_entry(yyvsp[0], 3)
    );
  }
#line 2186 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 54: /* variable: VAR_SIGN name  */
#line 281 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                          {
    yyval = MAKE_AST_NODE(VariableIdentifier, 3,
      rb_ary_entry(yyvsp[-1], 1),
      rb_ary_entry(yyvsp[-1], 2),
      rb_ary_entry(yyvsp[0], 3)
    );
  }
#line 2198 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 55: /* list_value: LBRACKET RBRACKET  */
#line 290 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                        { yyval = GraphQL_Language_Nodes_NONE; }
#line 2204 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 56: /* list_value: LBRACKET list_value_list RBRACKET  */
#line 291 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                        { yyval = yyvsp[-1]; }
#line 2210 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 57: /* list_value_list: input_value  */
#line 294 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                  { yyval = rb_ary_new_from_args(1, yyvsp[0]); }
#line 2216 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 58: /* list_value_list: list_value_list input_value  */
#line 295 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                  { rb_ary_push(yyval, yyvsp[0]); }
#line 2222 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 63: /* enum_value: enum_name  */
#line 303 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                        {
    yyval = MAKE_AST_NODE(Enum, 3,
      rb_ary_entry(yyvsp[0], 1),
      rb_ary_entry(yyvsp[0], 2),
      rb_ary_entry(yyvsp[0], 3)
    );
  }
#line 2234 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 64: /* object_value: LCURLY object_value_list_opt RCURLY  */
#line 312 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                        {
      yyval = MAKE_AST_NODE(InputObject, 3,
        rb_ary_entry(yyvsp[-2], 1),
        rb_ary_entry(yyvsp[-2], 2),
        yyvsp[-1]
      );
    }
#line 2246 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 65: /* object_value_list_opt: %empty  */
#line 321 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                        { yyval = GraphQL_Language_Nodes_NONE; }
#line 2252 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 67: /* object_value_list: object_value_field  */
#line 325 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                            { yyval = rb_ary_new_from_args(1, yyvsp[0]); }
#line 2258 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 68: /* object_value_list: object_value_list object_value_field  */
#line 326 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                            { rb_ary_push(yyval, yyvsp[0]); }
#line 2264 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 69: /* object_value_field: name COLON input_value  */
#line 329 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                             {
        yyval = MAKE_AST_NODE(Argument, 4,
          rb_ary_entry(yyvsp[-2], 1),
          rb_ary_entry(yyvsp[-2], 2),
          rb_ary_entry(yyvsp[-2], 3),
          yyvsp[0]
        );
      }
#line 2277 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 70: /* object_literal_value: LCURLY object_literal_value_list_opt RCURLY  */
#line 340 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                  {
        yyval = MAKE_AST_NODE(InputObject, 3,
          rb_ary_entry(yyvsp[-2], 1),
          rb_ary_entry(yyvsp[-2], 2),
          yyvsp[-1]
        );
      }
#line 2289 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 71: /* object_literal_value_list_opt: %empty  */
#line 349 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                { yyval = GraphQL_Language_Nodes_NONE; }
#line 2295 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 73: /* object_literal_value_list: object_literal_value_field  */
#line 353 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                            { yyval = rb_ary_new_from_args(1, yyvsp[0]); }
#line 2301 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 74: /* object_literal_value_list: object_literal_value_list object_literal_value_field  */
#line 354 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                            { rb_ary_push(yyval, yyvsp[0]); }
#line 2307 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 75: /* object_literal_value_field: name COLON literal_value  */
#line 357 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                               {
        yyval = MAKE_AST_NODE(Argument, 4,
          rb_ary_entry(yyvsp[-2], 1),
          rb_ary_entry(yyvsp[-2], 2),
          rb_ary_entry(yyvsp[-2], 3),
          yyvsp[0]
        );
      }
#line 2320 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 76: /* directives_list_opt: %empty  */
#line 368 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                      { yyval = GraphQL_Language_Nodes_NONE; }
#line 2326 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 78: /* directives_list: directive  */
#line 372 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                { yyval = rb_ary_new_from_args(1, yyvsp[0]); }
#line 2332 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 79: /* directives_list: directives_list directive  */
#line 373 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                { rb_ary_push(yyval, yyvsp[0]); }
#line 2338 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 80: /* directive: DIR_SIGN name arguments_opt  */
#line 375 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                         {
    yyval = MAKE_AST_NODE(Directive, 4,
      rb_ary_entry(yyvsp[-2], 1),
      rb_ary_entry(yyvsp[-2], 2),
      rb_ary_entry(yyvsp[-1], 3),
      yyvsp[0]
    );
  }
#line 2351 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 101: /* fragment_spread: ELLIPSIS name_without_on directives_list_opt  */
#line 412 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                   {
        yyval = MAKE_AST_NODE(FragmentSpread, 4,
          rb_ary_entry(yyvsp[-2], 1),
          rb_ary_entry(yyvsp[-2], 2),
          rb_ary_entry(yyvsp[-1], 3),
          yyvsp[0]
        );
      }
#line 2364 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 102: /* inline_fragment: ELLIPSIS ON type directives_list_opt selection_set  */
#line 422 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                         {
        yyval = MAKE_AST_NODE(InlineFragment, 5,
          rb_ary_entry(yyvsp[-4], 1),
          rb_ary_entry(yyvsp[-4], 2),
          yyvsp[-2],
          yyvsp[-1],
          yyvsp[0]
        );
      }
#line 2378 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 103: /* inline_fragment: ELLIPSIS directives_list_opt selection_set  */
#line 431 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                 {
        yyval = MAKE_AST_NODE(InlineFragment, 5,
          rb_ary_entry(yyvsp[-2], 1),
          rb_ary_entry(yyvsp[-2], 2),
          Qnil,
          yyvsp[-1],
          yyvsp[0]
        );
      }
#line 2392 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 104: /* fragment_definition: FRAGMENT fragment_name_opt ON type directives_list_opt selection_set  */
#line 442 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                                         {
      yyval = MAKE_AST_NODE(FragmentDefinition, 6,
        rb_ary_entry(yyvsp[-5], 1),
        rb_ary_entry(yyvsp[-5], 2),
        yyvsp[-4],
        yyvsp[-2],
        yyvsp[-1],
        yyvsp[0]
      );
    }
#line 2407 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 105: /* fragment_name_opt: %empty  */
#line 454 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                 { yyval = Qnil; }
#line 2413 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 106: /* fragment_name_opt: name_without_on  */
#line 455 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                      { yyval = rb_ary_entry(yyvsp[0], 3); }
#line 2419 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 108: /* type: nullable_type BANG  */
#line 459 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                              { yyval = MAKE_AST_NODE(NonNullType, 3, rb_funcall(yyvsp[-1], rb_intern("line"), 0), rb_funcall(yyvsp[-1], rb_intern("col"), 0), yyvsp[-1]); }
#line 2425 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 109: /* nullable_type: name  */
#line 462 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                             {
        yyval = MAKE_AST_NODE(TypeName, 3,
          rb_ary_entry(yyvsp[0], 1),
          rb_ary_entry(yyvsp[0], 2),
          rb_ary_entry(yyvsp[0], 3)
        );
      }
#line 2437 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 110: /* nullable_type: LBRACKET type RBRACKET  */
#line 469 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                             {
        yyval = MAKE_AST_NODE(ListType, 3,
          rb_funcall(yyvsp[-1], rb_intern("line"), 0),
          rb_funcall(yyvsp[-1], rb_intern("col"), 0),
          yyvsp[-1]
        );
      }
#line 2449 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 114: /* schema_definition: SCHEMA directives_list_opt operation_type_definition_list_opt  */
#line 483 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                                    {
        yyval = MAKE_AST_NODE(SchemaDefinition, 6,
          rb_ary_entry(yyvsp[-2], 1),
          rb_ary_entry(yyvsp[-2], 2),
          // TODO use static strings:
          rb_hash_aref(yyvsp[0], rb_str_new_cstr("query")),
          rb_hash_aref(yyvsp[0], rb_str_new_cstr("mutation")),
          rb_hash_aref(yyvsp[0], rb_str_new_cstr("subscription")),
          yyvsp[-1]
        );
      }
#line 2465 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 115: /* operation_type_definition_list_opt: %empty  */
#line 496 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                 { yyval = rb_hash_new(); }
#line 2471 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 116: /* operation_type_definition_list_opt: LCURLY operation_type_definition_list RCURLY  */
#line 497 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                   { yyval = yyvsp[-1]; }
#line 2477 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 117: /* operation_type_definition_list: operation_type_definition  */
#line 500 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                {
        yyval = rb_hash_new();
        rb_hash_aset(yyval, rb_ary_entry(yyvsp[0], 0), rb_ary_entry(yyvsp[0], 1));
      }
#line 2486 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 118: /* operation_type_definition_list: operation_type_definition_list operation_type_definition  */
#line 504 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                               {
      rb_hash_aset(yyval, rb_ary_entry(yyvsp[0], 0), rb_ary_entry(yyvsp[0], 1));
    }
#line 2494 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 119: /* operation_type_definition: operation_type COLON name  */
#line 509 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                {
        yyval = rb_ary_new_from_args(2, rb_ary_entry(yyvsp[-2], 3), rb_ary_entry(yyvsp[0], 3));
      }
#line 2502 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 127: /* description_opt: %empty  */
#line 524 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                      { yyval = Qnil; }
#line 2508 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 129: /* scalar_type_definition: description_opt SCALAR name directives_list_opt  */
#line 528 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                      {
        yyval = MAKE_AST_NODE(ScalarTypeDefinition, 5,
          rb_ary_entry(yyvsp[-2], 1),
          rb_ary_entry(yyvsp[-2], 2),
          rb_ary_entry(yyvsp[-1], 3),
          // TODO see get_description for reading a description from comments
          (RB_TEST(yyvsp[-3]) ? rb_ary_entry(yyvsp[-3], 3) : Qnil),
          yyvsp[0]
        );
      }
#line 2523 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 130: /* object_type_definition: description_opt TYPE_LITERAL name implements_opt directives_list_opt field_definition_list_opt  */
#line 540 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                                                                     {
        yyval = MAKE_AST_NODE(ObjectTypeDefinition, 7,
          rb_ary_entry(yyvsp[-4], 1),
          rb_ary_entry(yyvsp[-4], 2),
          rb_ary_entry(yyvsp[-3], 3),
          yyvsp[-2], // implements
          // TODO see get_description for reading a description from comments
          (RB_TEST(yyvsp[-5]) ? rb_ary_entry(yyvsp[-5], 3) : Qnil),
          yyvsp[-1],
          yyvsp[0]
        );
      }
#line 2540 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 131: /* implements_opt: %empty  */
#line 554 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                 { yyval = GraphQL_Language_Nodes_NONE; }
#line 2546 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 132: /* implements_opt: IMPLEMENTS AMP interfaces_list  */
#line 555 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                     { yyval = yyvsp[0]; }
#line 2552 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 133: /* implements_opt: IMPLEMENTS interfaces_list  */
#line 556 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                 { yyval = yyvsp[0]; }
#line 2558 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 134: /* implements_opt: IMPLEMENTS legacy_interfaces_list  */
#line 557 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                        { yyval = yyvsp[0]; }
#line 2564 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 135: /* interfaces_list: name  */
#line 560 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
           {
        VALUE new_name = MAKE_AST_NODE(TypeName, 3,
          rb_ary_entry(yyvsp[0], 1),
          rb_ary_entry(yyvsp[0], 2),
          rb_ary_entry(yyvsp[0], 3)
        );
        yyval = rb_ary_new_from_args(1, new_name);
      }
#line 2577 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 136: /* interfaces_list: interfaces_list AMP name  */
#line 568 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                               {
      VALUE new_name =  MAKE_AST_NODE(TypeName, 3, rb_ary_entry(yyvsp[0], 1), rb_ary_entry(yyvsp[0], 2), rb_ary_entry(yyvsp[0], 3));
      rb_ary_push(yyval, new_name);
    }
#line 2586 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 137: /* legacy_interfaces_list: name  */
#line 574 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
           {
        VALUE new_name = MAKE_AST_NODE(TypeName, 3,
          rb_ary_entry(yyvsp[0], 1),
          rb_ary_entry(yyvsp[0], 2),
          rb_ary_entry(yyvsp[0], 3)
        );
        yyval = rb_ary_new_from_args(1, new_name);
      }
#line 2599 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 138: /* legacy_interfaces_list: legacy_interfaces_list name  */
#line 582 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                  {
      rb_ary_push(yyval, MAKE_AST_NODE(TypeName, 3, rb_ary_entry(yyvsp[0], 1), rb_ary_entry(yyvsp[0], 2), rb_ary_entry(yyvsp[0], 3)));
    }
#line 2607 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 139: /* input_value_definition: description_opt name COLON type default_value_opt directives_list_opt  */
#line 587 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                                            {
        yyval = MAKE_AST_NODE(InputValueDefinition, 7,
          rb_ary_entry(yyvsp[-4], 1),
          rb_ary_entry(yyvsp[-4], 2),
          rb_ary_entry(yyvsp[-4], 3),
          yyvsp[-2],
          yyvsp[-1],
          // TODO see get_description for reading a description from comments
          (RB_TEST(yyvsp[-5]) ? rb_ary_entry(yyvsp[-5], 3) : Qnil),
          yyvsp[0]
        );
      }
#line 2624 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 140: /* input_value_definition_list: input_value_definition  */
#line 601 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                         { yyval = rb_ary_new_from_args(1, yyvsp[0]); }
#line 2630 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 141: /* input_value_definition_list: input_value_definition_list input_value_definition  */
#line 602 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                         { rb_ary_push(yyval, yyvsp[0]); }
#line 2636 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 142: /* arguments_definitions_opt: %empty  */
#line 605 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                { yyval = GraphQL_Language_Nodes_NONE; }
#line 2642 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 143: /* arguments_definitions_opt: LPAREN input_value_definition_list RPAREN  */
#line 606 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                { yyval = yyvsp[-1]; }
#line 2648 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 144: /* field_definition: description_opt name arguments_definitions_opt COLON type directives_list_opt  */
#line 609 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                                                    {
        yyval = MAKE_AST_NODE(FieldDefinition, 7,
          rb_ary_entry(yyvsp[-4], 1),
          rb_ary_entry(yyvsp[-4], 2),
          rb_ary_entry(yyvsp[-4], 3),
          yyvsp[-1],
          // TODO see get_description for reading a description from comments
          (RB_TEST(yyvsp[-5]) ? rb_ary_entry(yyvsp[-5], 3) : Qnil),
          yyvsp[-3],
          yyvsp[0]
        );
      }
#line 2665 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 145: /* field_definition_list_opt: %empty  */
#line 623 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
               { yyval = GraphQL_Language_Nodes_NONE; }
#line 2671 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 146: /* field_definition_list_opt: LCURLY field_definition_list RCURLY  */
#line 624 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                          { yyval = yyvsp[-1]; }
#line 2677 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 147: /* field_definition_list: %empty  */
#line 627 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                                                { yyval = GraphQL_Language_Nodes_NONE; }
#line 2683 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 148: /* field_definition_list: field_definition  */
#line 628 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                             { yyval = rb_ary_new_from_args(1, yyvsp[0]); }
#line 2689 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 149: /* field_definition_list: field_definition_list field_definition  */
#line 629 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                             { rb_ary_push(yyval, yyvsp[0]); }
#line 2695 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 150: /* interface_type_definition: description_opt INTERFACE name implements_opt directives_list_opt field_definition_list_opt  */
#line 632 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                                                                  {
        yyval = MAKE_AST_NODE(InterfaceTypeDefinition, 7,
          rb_ary_entry(yyvsp[-4], 1),
          rb_ary_entry(yyvsp[-4], 2),
          rb_ary_entry(yyvsp[-3], 3),
          // TODO see get_description for reading a description from comments
          (RB_TEST(yyvsp[-5]) ? rb_ary_entry(yyvsp[-5], 3) : Qnil),
          yyvsp[-2],
          yyvsp[-1],
          yyvsp[0]
        );
      }
#line 2712 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 151: /* pipe_opt: %empty  */
#line 646 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                 { yyval = GraphQL_Language_Nodes_NONE; }
#line 2718 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 152: /* pipe_opt: PIPE  */
#line 647 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
               { yyval = GraphQL_Language_Nodes_NONE; }
#line 2724 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 153: /* union_members: pipe_opt name  */
#line 650 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                    {
        VALUE new_member = MAKE_AST_NODE(TypeName, 3,
          rb_ary_entry(yyvsp[0], 1),
          rb_ary_entry(yyvsp[0], 2),
          rb_ary_entry(yyvsp[0], 3)
        );
        yyval = rb_ary_new_from_args(1, new_member);
      }
#line 2737 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 154: /* union_members: union_members PIPE name  */
#line 658 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                              {
        rb_ary_push(yyval, MAKE_AST_NODE(TypeName, 3, rb_ary_entry(yyvsp[0], 1), rb_ary_entry(yyvsp[0], 2), rb_ary_entry(yyvsp[0], 3)));
      }
#line 2745 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 155: /* union_type_definition: description_opt UNION name directives_list_opt EQUALS union_members  */
#line 663 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                                          {
        yyval = MAKE_AST_NODE(UnionTypeDefinition,  6,
          rb_ary_entry(yyvsp[-4], 1),
          rb_ary_entry(yyvsp[-4], 2),
          rb_ary_entry(yyvsp[-3], 3),
          yyvsp[0], // types
          // TODO see get_description for reading a description from comments
          (RB_TEST(yyvsp[-5]) ? rb_ary_entry(yyvsp[-5], 3) : Qnil),
          yyvsp[-2]
        );
      }
#line 2761 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 156: /* enum_type_definition: description_opt ENUM name directives_list_opt LCURLY enum_value_definitions RCURLY  */
#line 676 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                                                         {
        yyval = MAKE_AST_NODE(EnumTypeDefinition,  6,
          rb_ary_entry(yyvsp[-5], 1),
          rb_ary_entry(yyvsp[-5], 2),
          rb_ary_entry(yyvsp[-4], 3),
          // TODO see get_description for reading a description from comments
          (RB_TEST(yyvsp[-6]) ? rb_ary_entry(yyvsp[-6], 3) : Qnil),
          yyvsp[-3],
          yyvsp[-1]
        );
      }
#line 2777 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 157: /* enum_value_definition: description_opt enum_name directives_list_opt  */
#line 689 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                  {
      yyval = MAKE_AST_NODE(EnumValueDefinition, 5,
        rb_ary_entry(yyvsp[-1], 1),
        rb_ary_entry(yyvsp[-1], 2),
        rb_ary_entry(yyvsp[-1], 3),
        // TODO see get_description for reading a description from comments
        (RB_TEST(yyvsp[-2]) ? rb_ary_entry(yyvsp[-2], 3) : Qnil),
        yyvsp[0]
      );
    }
#line 2792 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 158: /* enum_value_definitions: enum_value_definition  */
#line 701 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                   { yyval = rb_ary_new_from_args(1, yyvsp[0]); }
#line 2798 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 159: /* enum_value_definitions: enum_value_definitions enum_value_definition  */
#line 702 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                   { rb_ary_push(yyval, yyvsp[0]); }
#line 2804 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 160: /* input_object_type_definition: description_opt INPUT name directives_list_opt LCURLY input_value_definition_list RCURLY  */
#line 705 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                                                               {
        yyval = MAKE_AST_NODE(InputObjectTypeDefinition, 6,
          rb_ary_entry(yyvsp[-5], 1),
          rb_ary_entry(yyvsp[-5], 2),
          rb_ary_entry(yyvsp[-4], 3),
          // TODO see get_description for reading a description from comments
          (RB_TEST(yyvsp[-6]) ? rb_ary_entry(yyvsp[-6], 3) : Qnil),
          yyvsp[-3],
          yyvsp[-1]
        );
      }
#line 2820 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 161: /* directive_definition: description_opt DIRECTIVE DIR_SIGN name arguments_definitions_opt directive_repeatable_opt ON directive_locations  */
#line 718 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                                                                                        {
        yyval = MAKE_AST_NODE(DirectiveDefinition, 7,
          rb_ary_entry(yyvsp[-6], 1),
          rb_ary_entry(yyvsp[-6], 2),
          rb_ary_entry(yyvsp[-4], 3),
          (RB_TEST(yyvsp[-2]) ? Qtrue : Qfalse), // repeatable
          // TODO see get_description for reading a description from comments
          (RB_TEST(yyvsp[-7]) ? rb_ary_entry(yyvsp[-7], 3) : Qnil),
          yyvsp[-3],
          yyvsp[0]
        );
      }
#line 2837 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 162: /* directive_repeatable_opt: %empty  */
#line 732 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                    { yyval = Qnil; }
#line 2843 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 163: /* directive_repeatable_opt: REPEATABLE  */
#line 733 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                    { yyval = Qtrue; }
#line 2849 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 164: /* directive_locations: name  */
#line 736 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                    { yyval = rb_ary_new_from_args(1, MAKE_AST_NODE(DirectiveLocation, 3, rb_ary_entry(yyvsp[0], 1), rb_ary_entry(yyvsp[0], 2), rb_ary_entry(yyvsp[0], 3))); }
#line 2855 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 165: /* directive_locations: directive_locations PIPE name  */
#line 737 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                    { rb_ary_push(yyval, MAKE_AST_NODE(DirectiveLocation, 3, rb_ary_entry(yyvsp[0], 1), rb_ary_entry(yyvsp[0], 2), rb_ary_entry(yyvsp[0], 3))); }
#line 2861 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 168: /* schema_extension: EXTEND SCHEMA directives_list_opt LCURLY operation_type_definition_list RCURLY  */
#line 745 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                                                     {
        yyval = MAKE_AST_NODE(SchemaExtension, 6,
          rb_ary_entry(yyvsp[-5], 1),
          rb_ary_entry(yyvsp[-5], 2),
          // TODO use static strings:
          rb_hash_aref(yyvsp[-1], rb_str_new_cstr("query")),
          rb_hash_aref(yyvsp[-1], rb_str_new_cstr("mutation")),
          rb_hash_aref(yyvsp[-1], rb_str_new_cstr("subscription")),
          yyvsp[-3]
        );
      }
#line 2877 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 169: /* schema_extension: EXTEND SCHEMA directives_list  */
#line 756 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                    {
        yyval = MAKE_AST_NODE(SchemaExtension, 6,
          rb_ary_entry(yyvsp[-2], 1),
          rb_ary_entry(yyvsp[-2], 2),
          Qnil,
          Qnil,
          Qnil,
          yyvsp[0]
        );
      }
#line 2892 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 176: /* scalar_type_extension: EXTEND SCALAR name directives_list  */
#line 775 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                            {
    yyval = MAKE_AST_NODE(ScalarTypeExtension, 4,
      rb_ary_entry(yyvsp[-3], 1),
      rb_ary_entry(yyvsp[-3], 2),
      rb_ary_entry(yyvsp[-1], 3),
      yyvsp[0]
    );
  }
#line 2905 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 177: /* object_type_extension: EXTEND TYPE_LITERAL name implements_opt directives_list_opt field_definition_list_opt  */
#line 785 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                                                            {
        yyval = MAKE_AST_NODE(ObjectTypeExtension, 6,
          rb_ary_entry(yyvsp[-5], 1),
          rb_ary_entry(yyvsp[-5], 2),
          rb_ary_entry(yyvsp[-3], 3),
          yyvsp[-2], // implements
          yyvsp[-1],
          yyvsp[0]
        );
      }
#line 2920 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 178: /* interface_type_extension: EXTEND INTERFACE name implements_opt directives_list_opt field_definition_list_opt  */
#line 797 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                                                         {
        yyval = MAKE_AST_NODE(InterfaceTypeExtension, 6,
          rb_ary_entry(yyvsp[-5], 1),
          rb_ary_entry(yyvsp[-5], 2),
          rb_ary_entry(yyvsp[-3], 3),
          yyvsp[-2],
          yyvsp[-1],
          yyvsp[0]
        );
      }
#line 2935 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 179: /* union_type_extension: EXTEND UNION name directives_list_opt EQUALS union_members  */
#line 809 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                                 {
        yyval = MAKE_AST_NODE(UnionTypeExtension, 5,
          rb_ary_entry(yyvsp[-5], 1),
          rb_ary_entry(yyvsp[-5], 2),
          rb_ary_entry(yyvsp[-3], 3),
          yyvsp[0], // types
          yyvsp[-2]
        );
      }
#line 2949 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 180: /* union_type_extension: EXTEND UNION name directives_list  */
#line 818 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                        {
        yyval = MAKE_AST_NODE(UnionTypeExtension, 5,
          rb_ary_entry(yyvsp[-3], 1),
          rb_ary_entry(yyvsp[-3], 2),
          rb_ary_entry(yyvsp[-1], 3),
          GraphQL_Language_Nodes_NONE, // types
          yyvsp[0]
        );
      }
#line 2963 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 181: /* enum_type_extension: EXTEND ENUM name directives_list_opt LCURLY enum_value_definitions RCURLY  */
#line 829 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                                                {
        yyval = MAKE_AST_NODE(EnumTypeExtension, 5,
          rb_ary_entry(yyvsp[-6], 1),
          rb_ary_entry(yyvsp[-6], 2),
          rb_ary_entry(yyvsp[-4], 3),
          yyvsp[-3],
          yyvsp[-1]
        );
      }
#line 2977 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 182: /* enum_type_extension: EXTEND ENUM name directives_list  */
#line 838 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                       {
        yyval = MAKE_AST_NODE(EnumTypeExtension, 5,
          rb_ary_entry(yyvsp[-3], 1),
          rb_ary_entry(yyvsp[-3], 2),
          rb_ary_entry(yyvsp[-1], 3),
          yyvsp[0],
          GraphQL_Language_Nodes_NONE
        );
      }
#line 2991 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 183: /* input_object_type_extension: EXTEND INPUT name directives_list_opt LCURLY input_value_definition_list RCURLY  */
#line 849 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                                                      {
        yyval = MAKE_AST_NODE(InputObjectTypeExtension, 5,
          rb_ary_entry(yyvsp[-6], 1),
          rb_ary_entry(yyvsp[-6], 2),
          rb_ary_entry(yyvsp[-4], 3),
          yyvsp[-3],
          yyvsp[-1]
        );
      }
#line 3005 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 184: /* input_object_type_extension: EXTEND INPUT name directives_list  */
#line 858 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                        {
        yyval = MAKE_AST_NODE(InputObjectTypeExtension, 5,
          rb_ary_entry(yyvsp[-3], 1),
          rb_ary_entry(yyvsp[-3], 2),
          rb_ary_entry(yyvsp[-1], 3),
          yyvsp[0],
          GraphQL_Language_Nodes_NONE
        );
      }
#line 3019 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;


#line 3023 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"

      default: break;
    }
  /* User semantic actions sometimes alter yychar, and that requires
     that yytoken be updated with the new translation.  We take the
     approach of translating immediately before every use of yytoken.
     One alternative is translating here after every semantic action,
     but that translation would be missed if the semantic action invokes
     YYABORT, YYACCEPT, or YYERROR immediately after altering yychar or
     if it invokes YYBACKUP.  In the case of YYABORT or YYACCEPT, an
     incorrect destructor might then be invoked immediately.  In the
     case of YYERROR or YYBACKUP, subsequent parser actions might lead
     to an incorrect destructor call or verbose syntax error message
     before the lookahead is translated.  */
  YY_SYMBOL_PRINT ("-> $$ =", YY_CAST (yysymbol_kind_t, yyr1[yyn]), &yyval, &yyloc);

  YYPOPSTACK (yylen);
  yylen = 0;

  *++yyvsp = yyval;

  /* Now 'shift' the result of the reduction.  Determine what state
     that goes to, based on the state we popped back to and the rule
     number reduced by.  */
  {
    const int yylhs = yyr1[yyn] - YYNTOKENS;
    const int yyi = yypgoto[yylhs] + *yyssp;
    yystate = (0 <= yyi && yyi <= YYLAST && yycheck[yyi] == *yyssp
               ? yytable[yyi]
               : yydefgoto[yylhs]);
  }

  goto yynewstate;


/*--------------------------------------.
| yyerrlab -- here on detecting error.  |
`--------------------------------------*/
yyerrlab:
  /* Make sure we have latest lookahead translation.  See comments at
     user semantic actions for why this is necessary.  */
  yytoken = yychar == YYEMPTY ? YYSYMBOL_YYEMPTY : YYTRANSLATE (yychar);
  /* If not already recovering from an error, report this error.  */
  if (!yyerrstatus)
    {
      ++yynerrs;
      {
        yypcontext_t yyctx
          = {yyssp, yytoken};
        char const *yymsgp = YY_("syntax error");
        int yysyntax_error_status;
        yysyntax_error_status = yysyntax_error (&yymsg_alloc, &yymsg, &yyctx);
        if (yysyntax_error_status == 0)
          yymsgp = yymsg;
        else if (yysyntax_error_status == -1)
          {
            if (yymsg != yymsgbuf)
              YYSTACK_FREE (yymsg);
            yymsg = YY_CAST (char *,
                             YYSTACK_ALLOC (YY_CAST (YYSIZE_T, yymsg_alloc)));
            if (yymsg)
              {
                yysyntax_error_status
                  = yysyntax_error (&yymsg_alloc, &yymsg, &yyctx);
                yymsgp = yymsg;
              }
            else
              {
                yymsg = yymsgbuf;
                yymsg_alloc = sizeof yymsgbuf;
                yysyntax_error_status = YYENOMEM;
              }
          }
        yyerror (parser, filename, yymsgp);
        if (yysyntax_error_status == YYENOMEM)
          YYNOMEM;
      }
    }

  if (yyerrstatus == 3)
    {
      /* If just tried and failed to reuse lookahead token after an
         error, discard it.  */

      if (yychar <= YYEOF)
        {
          /* Return failure if at end of input.  */
          if (yychar == YYEOF)
            YYABORT;
        }
      else
        {
          yydestruct ("Error: discarding",
                      yytoken, &yylval, parser, filename);
          yychar = YYEMPTY;
        }
    }

  /* Else will try to reuse lookahead token after shifting the error
     token.  */
  goto yyerrlab1;


/*---------------------------------------------------.
| yyerrorlab -- error raised explicitly by YYERROR.  |
`---------------------------------------------------*/
yyerrorlab:
  /* Pacify compilers when the user code never invokes YYERROR and the
     label yyerrorlab therefore never appears in user code.  */
  if (0)
    YYERROR;
  ++yynerrs;

  /* Do not reclaim the symbols of the rule whose action triggered
     this YYERROR.  */
  YYPOPSTACK (yylen);
  yylen = 0;
  YY_STACK_PRINT (yyss, yyssp);
  yystate = *yyssp;
  goto yyerrlab1;


/*-------------------------------------------------------------.
| yyerrlab1 -- common code for both syntax error and YYERROR.  |
`-------------------------------------------------------------*/
yyerrlab1:
  yyerrstatus = 3;      /* Each real token shifted decrements this.  */

  /* Pop stack until we find a state that shifts the error token.  */
  for (;;)
    {
      yyn = yypact[yystate];
      if (!yypact_value_is_default (yyn))
        {
          yyn += YYSYMBOL_YYerror;
          if (0 <= yyn && yyn <= YYLAST && yycheck[yyn] == YYSYMBOL_YYerror)
            {
              yyn = yytable[yyn];
              if (0 < yyn)
                break;
            }
        }

      /* Pop the current state because it cannot handle the error token.  */
      if (yyssp == yyss)
        YYABORT;


      yydestruct ("Error: popping",
                  YY_ACCESSING_SYMBOL (yystate), yyvsp, parser, filename);
      YYPOPSTACK (1);
      yystate = *yyssp;
      YY_STACK_PRINT (yyss, yyssp);
    }

  YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
  *++yyvsp = yylval;
  YY_IGNORE_MAYBE_UNINITIALIZED_END


  /* Shift the error token.  */
  YY_SYMBOL_PRINT ("Shifting", YY_ACCESSING_SYMBOL (yyn), yyvsp, yylsp);

  yystate = yyn;
  goto yynewstate;


/*-------------------------------------.
| yyacceptlab -- YYACCEPT comes here.  |
`-------------------------------------*/
yyacceptlab:
  yyresult = 0;
  goto yyreturnlab;


/*-----------------------------------.
| yyabortlab -- YYABORT comes here.  |
`-----------------------------------*/
yyabortlab:
  yyresult = 1;
  goto yyreturnlab;


/*-----------------------------------------------------------.
| yyexhaustedlab -- YYNOMEM (memory exhaustion) comes here.  |
`-----------------------------------------------------------*/
yyexhaustedlab:
  yyerror (parser, filename, YY_("memory exhausted"));
  yyresult = 2;
  goto yyreturnlab;


/*----------------------------------------------------------.
| yyreturnlab -- parsing is finished, clean up and return.  |
`----------------------------------------------------------*/
yyreturnlab:
  if (yychar != YYEMPTY)
    {
      /* Make sure we have latest lookahead translation.  See comments at
         user semantic actions for why this is necessary.  */
      yytoken = YYTRANSLATE (yychar);
      yydestruct ("Cleanup: discarding lookahead",
                  yytoken, &yylval, parser, filename);
    }
  /* Do not reclaim the symbols of the rule whose action triggered
     this YYABORT or YYACCEPT.  */
  YYPOPSTACK (yylen);
  YY_STACK_PRINT (yyss, yyssp);
  while (yyssp != yyss)
    {
      yydestruct ("Cleanup: popping",
                  YY_ACCESSING_SYMBOL (+*yyssp), yyvsp, parser, filename);
      YYPOPSTACK (1);
    }
#ifndef yyoverflow
  if (yyss != yyssa)
    YYSTACK_FREE (yyss);
#endif
  if (yymsg != yymsgbuf)
    YYSTACK_FREE (yymsg);
  return yyresult;
}

#line 868 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"


// Custom functions
int yylex (YYSTYPE *lvalp, VALUE parser, VALUE filename) {
  VALUE next_token_idx_rb_int = rb_ivar_get(parser, rb_intern("@next_token_index"));
  int next_token_idx = FIX2INT(next_token_idx_rb_int);
  VALUE tokens = rb_ivar_get(parser, rb_intern("@tokens"));
  VALUE next_token = rb_ary_entry(tokens, next_token_idx);

  if (!RB_TEST(next_token)) {
    return YYEOF;
  }
  rb_ivar_set(parser, rb_intern("@next_token_index"), INT2FIX(next_token_idx + 1));
  VALUE token_type_rb_int = rb_ary_entry(next_token, 4);
  int next_token_type = FIX2INT(token_type_rb_int);
  if (next_token_type == 241) { // BAD_UNICODE_ESCAPE
    VALUE mGraphQL = rb_const_get_at(rb_cObject, rb_intern("GraphQL"));
    VALUE mCParser = rb_const_get_at(mGraphQL, rb_intern("CParser"));
    VALUE bad_unicode_error = rb_funcall(
        mCParser, rb_intern("prepare_bad_unicode_error"), 1,
        parser
    );
    rb_exc_raise(bad_unicode_error);
  }
  *lvalp = next_token;
  return next_token_type;
}

void yyerror(VALUE parser, VALUE filename, const char *msg) {
  VALUE mGraphQL = rb_const_get_at(rb_cObject, rb_intern("GraphQL"));
  VALUE mCParser = rb_const_get_at(mGraphQL, rb_intern("CParser"));
  VALUE rb_message = rb_str_new_cstr(msg);
  VALUE exception = rb_funcall(
      mCParser, rb_intern("prepare_parse_error"), 2,
      rb_message,
      parser
  );
  rb_exc_raise(exception);
}

#define INITIALIZE_NODE_CLASS_VARIABLE(node_class_name) \
    rb_global_variable(&GraphQL_Language_Nodes_##node_class_name); \
    GraphQL_Language_Nodes_##node_class_name = rb_const_get_at(mGraphQLLanguageNodes, rb_intern(#node_class_name));

void initialize_node_class_variables() {
  VALUE mGraphQL = rb_const_get_at(rb_cObject, rb_intern("GraphQL"));
  VALUE mGraphQLLanguage = rb_const_get_at(mGraphQL, rb_intern("Language"));
  VALUE mGraphQLLanguageNodes = rb_const_get_at(mGraphQLLanguage, rb_intern("Nodes"));

  rb_global_variable(&GraphQL_Language_Nodes_NONE);
  GraphQL_Language_Nodes_NONE = rb_ary_new();
  rb_ary_freeze(GraphQL_Language_Nodes_NONE);

  rb_global_variable(&r_string_query);
  r_string_query = rb_str_new_cstr("query");
  rb_str_freeze(r_string_query);

  INITIALIZE_NODE_CLASS_VARIABLE(Argument)
  INITIALIZE_NODE_CLASS_VARIABLE(Directive)
  INITIALIZE_NODE_CLASS_VARIABLE(Document)
  INITIALIZE_NODE_CLASS_VARIABLE(Enum)
  INITIALIZE_NODE_CLASS_VARIABLE(Field)
  INITIALIZE_NODE_CLASS_VARIABLE(FragmentDefinition)
  INITIALIZE_NODE_CLASS_VARIABLE(FragmentSpread)
  INITIALIZE_NODE_CLASS_VARIABLE(InlineFragment)
  INITIALIZE_NODE_CLASS_VARIABLE(InputObject)
  INITIALIZE_NODE_CLASS_VARIABLE(ListType)
  INITIALIZE_NODE_CLASS_VARIABLE(NonNullType)
  INITIALIZE_NODE_CLASS_VARIABLE(NullValue)
  INITIALIZE_NODE_CLASS_VARIABLE(OperationDefinition)
  INITIALIZE_NODE_CLASS_VARIABLE(TypeName)
  INITIALIZE_NODE_CLASS_VARIABLE(VariableDefinition)
  INITIALIZE_NODE_CLASS_VARIABLE(VariableIdentifier)

  INITIALIZE_NODE_CLASS_VARIABLE(ScalarTypeDefinition)
  INITIALIZE_NODE_CLASS_VARIABLE(ObjectTypeDefinition)
  INITIALIZE_NODE_CLASS_VARIABLE(InterfaceTypeDefinition)
  INITIALIZE_NODE_CLASS_VARIABLE(UnionTypeDefinition)
  INITIALIZE_NODE_CLASS_VARIABLE(EnumTypeDefinition)
  INITIALIZE_NODE_CLASS_VARIABLE(InputObjectTypeDefinition)
  INITIALIZE_NODE_CLASS_VARIABLE(EnumValueDefinition)
  INITIALIZE_NODE_CLASS_VARIABLE(DirectiveDefinition)
  INITIALIZE_NODE_CLASS_VARIABLE(DirectiveLocation)
  INITIALIZE_NODE_CLASS_VARIABLE(FieldDefinition)
  INITIALIZE_NODE_CLASS_VARIABLE(InputValueDefinition)
  INITIALIZE_NODE_CLASS_VARIABLE(SchemaDefinition)

  INITIALIZE_NODE_CLASS_VARIABLE(ScalarTypeExtension)
  INITIALIZE_NODE_CLASS_VARIABLE(ObjectTypeExtension)
  INITIALIZE_NODE_CLASS_VARIABLE(InterfaceTypeExtension)
  INITIALIZE_NODE_CLASS_VARIABLE(UnionTypeExtension)
  INITIALIZE_NODE_CLASS_VARIABLE(EnumTypeExtension)
  INITIALIZE_NODE_CLASS_VARIABLE(InputObjectTypeExtension)
  INITIALIZE_NODE_CLASS_VARIABLE(SchemaExtension)
}
