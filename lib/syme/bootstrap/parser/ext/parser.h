#ifndef SYME_PARSER_H
#define SYME_PARSER_H

#ifdef __cplusplus
extern "C" {
#endif

#ifndef O_BINARY
#define O_BINARY 0
#endif

typedef struct NewspeakParserState {
  unsigned int pos;
  unsigned int size;
  char*        bytes;
  VALUE        parser;
  VALUE        ast;
} Newspeak;

VALUE newspeak_parse(VALUE self, VALUE string);

#ifdef __cplusplus
}
#endif

#endif
