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

newspeak = language-id toplevel-class end-of-file

toplevel-class = class-category class-declaration
class-declaration = "class" class-header side-decl class-side-decl?
nested-class-decl = access-modifier? class-declaration

class-header = identifier (message-pattern | empty) equal-sign superclass-clause?
               left-paren class-comment? slot-decls? init-expressions right-paren
superclass-clause = slot-name message?
language-id = identifier
class-category = string?
class-comment = -
side-decl = left-paren nested-class-decl* category* right-paren
class-side-decl = colon left-paren category* right-paren
category = string method-decl*


method-def = method-decl | method
method-decl = access-modifier? message-pattern equal-sign
              left-paren code-body right-paren
method-header = access-modifier? message-pattern
method = message-pattern code-body end-of-file
message-pattern = unary-message-pattern
                  | binary-message-pattern
                  | keyword-message-pattern
unary-message-pattern = unary-selector
binary-message-pattern = binary-selector slot-decl
keyword-message-pattern = (keyword slot-decl)+

init-expressions = expression (dot expression)* dot?
block = left-bracket block-parameters? code-body right-bracket

code-body = temporaries? statements
temporaries = slot-decls
slot-decls = vbar slot-def* vbar
block-parameters = block-parameter? vbar
block-parameter = colon slot-decl
slot-decl = identifier
slot-def = access-modifier? slot-decl (( "=" | "::=" ) expression dot)?

access-modifier = (private | public | protected) -
private = pound "private"
public = pound "public"
protected = pound "protected"

statements = return-statement | statement-sequence | empty
statement-sequence = expression further-statements?
return-statement = hat expression dot?
further-statements = dot statements

expression = setter-keyword? send-expression
send-expression = keyword-here-send | cascaded-message-expression
cascaded-message-expression = primary message-cascade?
message-cascade = nonempty-messages cascade-message*
cascade-message = semicolon (keyword-message
                             | binary-message
                             | unary-selector)
keyword-here-send = keyword-message
keyword-expression = binary-expression keyword-message?
nonempty-messages = nontrivial-unary-messages
                    | nontrivial-binary-messages
                    | keyword-messages
keyword-messages = keyword-message
nontrivial-binary-messages = binary-message+ keyword-message?

nontrivial-unary-messages = unary-selector+ binary-message* keyword-message?
message = keyword-message | unary-selector | binary-message
keyword-message = (keyword binary-expression)+
binary-message = binary-selector unary-expression
binary-expression = unary-expression binary-message*
unary-expression = primary unary-selector*
primary = slot-name | literal | block | parenthesized-expression

parenthesized-expression = left-paren expression right-paren

slot-name = identifier
unary-selector = identifier

literal = number | symbol-constant | character-constant | string | tuple

tuple = left-curly (expression (dot expression)* dot?)? right-curly
empty = left-curly -- right-curly

symbol-constant = pound symbol
symbol = - sym
sym = str | kwds | bin-sel | id

binary-selector = - bin-sel
bin-sel = (special-character | '-') special-character*

setter-keyword = - kw colon

keyword = - kw
kwds = kw+
kw = id colon

str = ['] (character | space | '"' | two-quotes)* [']
string = - str
two-quotes = ['] [']

character-constant = - '$' (character | ['] | '"' | ' ')

identifier = - id
id = (letter | underscore) (letter | digit | underscore)*
character = digit | letter | special-character
            | left-bracket | right-bracket | left-curly | right-curly
            | left-paren | right-paren | hat | semicolon | dollar
            | pound | colon | dot | '-' | underscore | '`'
letter = [a-zA-Z]
special-character = [+/\\*~<>=@%|&?!,]
underscore = '_'

number = - radix-number | decimal-number
radix-number = radix '-'? extended-digits extended-fraction? exponent?
decimal-number = '-'? digits fraction? exponent?
exponent = 'e' '-'? digits

extended-fraction = dot extended-digits
radix = digits 'r'
fraction = dot digits

extended-digits = (digit | uppercase-letter)+
uppercase-letter = [A-Z]
digit = [0-9]
digits = digit+

colon = ':'
comma = ','
dollar = '$'
dot = '.'
equal-sign = '='
hat = '^'
left-bracket = '['
left-curly = '{'
left-paren = '('
left-angle = '<'
pound = '#'
right-angle = '>'
right-bracket = ']'
right-curly = '}'
right-paren = ')'
semicolon = ';'
slash = '/'
vbar = '|'

- = (space | comment)*
-- = (space | comment | end-of-line)*
comment	= comment-begin (!comment-end .)* comment-end
comment-begin = '"'
comment-end = '"'
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
