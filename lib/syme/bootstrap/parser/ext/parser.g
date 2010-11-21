#
# parser.g
# Newspeak grammar
#
# (c) 2010 Brian Ford

%{

#include "ruby.h"
#include "parser.h"

#define YY_INPUT(buf, result, max) {  \
  if (N->pos < N->size) {             \
    result = max;                     \
    if(N->pos + max > N->size)        \
      result = N->size - N->pos;      \
    memcpy(buf, N->bytes, result+1);  \
    N->pos += max;                    \
  } else {                            \
    result = 0;                       \
  }                                   \
}

#define YYSTYPE VALUE
#define YY_XTYPE Newspeak*
#define YY_XVAR N
#define YY_NAME(N) newspeak_code_##N

#define NS_VAL(n)         rb_funcall(N->parser, rb_intern(n), 0)
#define NS_AST(n, v)      rb_funcall(N->parser, rb_intern(n), 1, v)
#define NS_AST2(n, x, y)  rb_funcall(N->parser, rb_intern(n), 2, x, y)
#define NS_OP(n, l, r)    rb_funcall(N->parser, rb_intern(n), 2, l, r)

%}

newspeak = --

- = (space | comment)*
-- = (space | comment | end-of-line)*
comment	= '#' (!end-of-line)*
space = ' ' | '\f' | '\v' | '\t'
end-of-line = '\r\n' | '\n' | '\r'
end-of-file = !.

%%

VALUE newspeak_parse_string(VALUE self, VALUE string) {
  Newspeak N;

  N.parser = self;
  N.pos = 0;
  N.size = RSTRING_LEN(string);
  N.bytes = RSTRING_PTR(string);

  GREG *G = newspeak_code_parse_new(&N);
  G->pos = G->limit = 0;

  if (!newspeak_code_parse(G)) {
    rb_funcall(N.parser, rb_intern("syntax_error"), 1, INT2FIX(G->end));
    return N.ast = Qfalse;
  }
  newspeak_code_parse_free(G);

  return N.ast;
}

void Init_parser(void) {
  VALUE rb_mSyme = rb_const_get(rb_cObject, rb_intern("Syme"));
  VALUE rb_cParser = rb_const_get(rb_mSyme, rb_intern("Parser"));

  rb_define_method(rb_cParser, "parse_string", RUBY_METHOD_FUNC(newspeak_parse_string), 1);
}
