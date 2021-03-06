#ifndef _LAMBDACHINE_OPTS_H
#define _LAMBDACHINE_OPTS_H
typedef struct {
  const char  *input_file;
  const char  *main_closure;
  const char  *base_path;
  const char  *print_loader_state; /* Filename to print to */
  int          disable_jit;
  int          enable_asm;  /* enable machine code generation */
  const char  *step_opts;   /* Allow stepping through JIT phases */
  long         stack_size;
} Opts;
#endif
