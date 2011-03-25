#include "Loader.h"
#include "Thread.h"
#include "HashTable.h"
#include "PrintClosure.h"
#include "StorageManager.h"
#include "Stats.h"

#include <stdio.h>
#include <stdlib.h>
#include <getopt.h>

typedef struct {
  const char  *input_file;
  const char  *main_closure;
  int          print_loader_state;
  int          disable_jit;
} Opts;

#define MAX_CLOSURE_NAME_LEN 512

static Opts opts = {
  .input_file = "Bc0005",
  .main_closure = "test",
  .print_loader_state = 0,
  .disable_jit = 0
};

void loadWiredInModules();

int
main(int argc, char *argv[])
{
  Thread   *T0;
  Closure  *clos0;
  char main_clos_name[MAX_CLOSURE_NAME_LEN];

  // TODO: Parse flags

  static struct option long_options[] = {
    {"print-loader-state", no_argument, &opts.print_loader_state, 1},
    {"no-jit",             no_argument, &opts.disable_jit, 1},
    {"no-run",             no_argument, 0, 'l'},
    {"entry",              required_argument, 0, 'e'},
    {"help",               no_argument, 0, 'h'},
    {0, 0, 0, 0}
  };

  int c;

  while (1) {
    int option_index = 0;
    c = getopt_long(argc, argv, "he:", long_options, &option_index);

    if (c == -1)
      break;

    switch (c) {
    case 0:
      /* If this option set a flag, do nothing else now. */
      if (long_options[option_index].flag != 0)
        break;
      break;
    case 'e':
      printf("entry = %s\n", optarg);
      opts.main_closure = optarg;
      break;
    case 'l':
      opts.main_closure = NULL;
      break;
    case 'h':
      printf("Usage: %s [options] MODULE_NAME\n\n"
             "Options:\n"
             "  -h --help       Print this help.\n"
             "  -e --entry      Set entry point (default: test)\n"
             "     --no-run     Load module only.\n"
             "     --print-loader-state\n"
             "                  Print static closures and info tables after loading.\n"
             "     --no-jit     Don't enable JIT.\n"
             "\n",
             argv[0]);
      exit(0);
    default:
      printf("c = %d\n", c);
      abort();
    }
  }

  int nmodules = argc - optind;

  if (nmodules == 1) {
    opts.input_file = argv[optind];
  } else if (nmodules == 0) {
    fprintf(stderr, "No module specified.\n");
    exit(1);
  } else { // modules > 1
    fprintf(stderr, "Too many modules specified (%d).\n",
            nmodules);
    while (optind < argc)
      printf("%s\n", argv[optind++]);
    exit(1);
  }

  if (opts.main_closure != NULL) {
    int n = snprintf(main_clos_name, MAX_CLOSURE_NAME_LEN,
                     "%s.%s!closure", opts.input_file,
                     opts.main_closure);
    if (n <= MAX_CLOSURE_NAME_LEN) {
      opts.main_closure = main_clos_name;
    } else {
      fprintf(stderr, "ERROR: Main closure name too long.\n");
      exit(1);
    }
  }

  initVM();
  initStorageManager();
  initLoader();
  loadWiredInModules();
  loadModule(opts.input_file);

  if (opts.print_loader_state) {
    printLoaderState();
    fflush(stdout);
  }

  if (opts.main_closure == NULL) // Nothing to run, just quit.
    return 0;

  printf("----------------------------------------------------\n"
	 "Loaded %s, now evaluating '%s'\n", opts.input_file, opts.main_closure);

  clos0 = lookupClosure(opts.main_closure);
  if (clos0 == NULL) {
    fprintf(stderr, "ERROR: Closure not found: %s\n", opts.main_closure);
    exit(1);
  }

  if (opts.disable_jit)
    G_cap0->flags |= CF_NO_JIT;

  T0 = createThread(G_cap0, 1024);
  clos0 = startThread(T0, clos0);
  printClosure(clos0);
  printEvents();

  return 0;
}

void loadWiredInModules()
{
  loadModule("Control.Exception.Base");
}
