/**
   Tests "inspired" by the ones in dstep's UnitTests.d module
 */
module it.dstep.ut;

import it.compile;

@("2 functions and a global variable")
@safe unittest {
    with(immutable IncludeSandbox()) {
        expand(Out("dstep.d"), In("dstep.h"),
               q{
                   float foo(int x);
                   float bar(int x);
                   int a;
               });

        writeFile("main.d",
                  q{
                      import dstep;
                      void main() {
                          float f = foo(42);
                          float b = bar(77);
                          a = 33;
                      }
                  });

        shouldCompile("main.d", "dstep.d");
    }
}

@("extern int declared several times")
@safe unittest {
    with(immutable IncludeSandbox()) {
        expand(Out("dstep.d"), In("dstep.h"),
               q{
                   extern int foo;
                   extern int bar;
                   extern int foo;
                   extern int foo;
               });

        writeFile("main.d",
                  q{
                      import dstep;
                      void main() {
                          foo = 5;
                          bar = 3;
                      }
                  });

        shouldCompileButNotLink("main.d", "dstep.d");
    }
}

@("array with #defined length")
@safe unittest {
    with(immutable IncludeSandbox()) {
        writeFile("dstep.h",
                  q{
                      #define FOO 4
                      char var[FOO];
                  });

        writeFile("main.d_",
                  q{
                      #include "%s"
                      void main() {
                          static assert(var.sizeof == 4);
                          var[0] = cast(byte)3;
                      }
                  }.format(inSandboxPath("dstep.h")));

        preprocess("main.d_", "main.d");
        shouldCompile("main.d");
    }
}

@("struct with array with #defined length")
@safe unittest {
    with(immutable IncludeSandbox()) {
        writeFile("dstep.h",
                  q{
                      #define BAR 128

                      struct Foo {
                          char var[BAR];
                      };
                  });

        writeFile("main.d_",
                  q{
                      #include "%s"
                      void main() {
                          auto f = struct_Foo();
                          static assert(f.var.sizeof == 128);
                          f.var[127] = cast(byte)3;
                      }
                  }.format(inSandboxPath("dstep.h")));

        preprocess("main.d_", "main.d");
        shouldCompile("main.d");
    }
}


@("struct with 3d arrays of #defined length")
@safe unittest {
    with(immutable IncludeSandbox()) {
        writeFile("dstep.h",
                  q{
                      #define FOO 2
                      #define BAR 4
                      #define BAZ 8

                      struct Foo {
                          char var[FOO][BAR][BAZ];
                      };
                  });

        writeFile("main.d_",
                  q{
                      #include "%s"
                      void main() {
                          auto f = struct_Foo();
                          // opposite order than in C
                          static assert(f.var.length == 2);
                          static assert(f.var[0].length == 4);
                          static assert(f.var[0][0].length == 8);
                          auto v = f.var[0][0][7];
                      }
                  }.format(inSandboxPath("dstep.h")));

        preprocess("main.d_", "main.d");
        shouldCompile("main.d");
    }
}

@ShouldFail("BUG - using gLastNickName doesn't work")
@("nested anonymous structures with associated fields")
@safe unittest {
    with(immutable IncludeSandbox()) {
        expand(Out("dstep.d"), In("dstep.h"),
               q{
                   struct C {
                       struct {
                           int x;
                           int y;

                           struct {
                               int z;
                               int w;
                           } nested;
                       } point;
                   };
               });

        writeFile("main.d",
                  q{
                      import dstep;
                      void main() {
                          auto c = struct_C();
                          c.point.x = 42;
                          c.point.y = 77;
                          c.point.nested.z = 2;
                          c.point.nested.w = 3;
                      }
                  });

        shouldCompile("main.d", "dstep.d");
    }
}

@("interleaved enum-based array size consts and macro based array size counts")
@safe unittest {
    with(immutable IncludeSandbox()) {
        writeFile("dstep.h",
                  q{
                      struct qux {
                          char scale;
                      };

                      #define FOO 2
                      #define BAZ 8

                      struct stats_t {
                          enum
                          {
                              BAR = 4,
                          };

                          struct qux stat[FOO][BAR][FOO][BAZ];
                      };

                  });

        writeFile("main.d_",
                  q{
                      #include "%s"
                      void main() {
                          auto s = struct_stats_t();
                          // opposite order than in C
                          static assert(struct_stats_t.BAR == 4);
                          // accessing at the limits of each dimension
                          auto q = s.stat[1][3][1][7];
                      }
                  }.format(inSandboxPath("dstep.h")));

        preprocess("main.d_", "main.d");
        shouldCompile("main.d");
    }
}

@("function pointer with unnamed parameter")
@safe unittest {
    with(immutable IncludeSandbox()) {
        expand(Out("dstep.d"), In("dstep.h"),
               q{
                   typedef int (*read_char)(void *);
               });

        writeFile("main.d",
                  q{
                      import dstep;
                      void main() {
                          read_char func;
                          int val;
                          int ret = func(&val);
                      }
                  });

        shouldCompile("main.d", "dstep.d");
    }
}

@("array typedef")
@safe unittest {
    with(immutable IncludeSandbox()) {
        expand(Out("dstep.d"), In("dstep.h"),
               q{
                   typedef double foo[2];
               });

        writeFile("main.d",
                  q{
                      import dstep;
                      void main() {
                          foo doubles;
                          static assert(doubles.length == 2);
                          doubles[0] = 33.3;
                          doubles[1] = 77.7;
                      }
                  });

        shouldCompile("main.d", "dstep.d");
    }
}

@("array of structs declared immediately")
@safe unittest {
    with(immutable IncludeSandbox()) {
        expand(Out("dstep.d"), In("dstep.h"),
               q{
                   struct Foo {
                       struct Bar {
                       } bar[64];
                   };
               });

        writeFile("main.d",
                  q{
                      import dstep;
                      void main() {
                          auto f = struct_Foo();
                          static assert(f.bar.length == 64);
                          f.bar[63] = struct_Foo.struct_Bar();
                      }
                  });

        shouldCompile("main.d", "dstep.d");
    }
}

@("variadic function without ...")
@safe unittest {
    with(immutable IncludeSandbox()) {
        expand(Out("dstep.d"), In("dstep.h"),
               q{
                   void foo();
               });

        writeFile("main.d",
                  q{
                      import dstep;
                      void main() {
                      }
                  });

        // Fully variadic C functions aren't allowed in D.
        // The declaration is void foo(...) but D requires at least
        // one mandatory parameter.
        shouldNotCompile("main.d", "dstep.d");
    }
}


@ShouldFail("BUG - Uncovered unexposed case in include.translation.type hack")
@("function pointers")
@safe unittest {
    with(immutable IncludeSandbox()) {
        expand(Out("dstep.d"), In("dstep.h"),
               q{
                   typedef void *ClientData;
                   typedef struct { } EntityInfo;
                   void (*fun)(ClientData client_data, const EntityInfo*, unsigned last);
               });

        writeFile("main.d",
                  q{
                      import dstep;
                      void main() {
                          auto eInfo = EntityInfo();
                          struct Data { int value; }
                          auto data = Data(42);
                          uint last = 33;
                          fun theFunction;
                          fun(&data, &info, last);
                      }
                  });

        shouldCompile("main.d", "dstep.d");
    }
}


@ShouldFail("BUG - qux should be int[64]*, not int[64][32]")
@("array function parameters")
@safe unittest {
    with(immutable IncludeSandbox()) {
        expand(Out("dstep.d"), In("dstep.h"),
               q{
                   int foo (int data[]);             // int*
                   int bar (const int data[]);       // const int*
                   int baz (const int data[32]);     // const int*
                   int qux (const int data[32][64]); // const int(*)[64]
               });

        writeFile("main.d",
                  q{
                      import dstep;
                      void main() {
                          int* data;
                          foo(data);
                          bar(data);
                          baz(data);
                          static assert(!__traits(compiles, qux(data)));
                          const(int)[64] arr;
                          qux(&arr);
                      }
                  });

        shouldCompile("main.d", "dstep.d");
    }
}

@("name collision between struct and function")
@safe unittest {
    with(immutable IncludeSandbox()) {
        expand(Out("dstep.d"), In("dstep.h"),
               q{
                   struct foo;
                   struct foo { int i; };
                   void foo(void);
               });

        writeFile("main.d",
                  q{
                      import dstep;
                      void main() {
                          foo();
                      }
                  });

        shouldCompile("main.d", "dstep.d");
    }
}

@("name collision between struct and enum")
@safe unittest {
    with(immutable IncludeSandbox()) {
        expand(Out("dstep.d"), In("dstep.h"),
               q{
                   enum foo { FOO };
                   void foo(void);
               });

        writeFile("main.d",
                  q{
                      import dstep;
                      void main() {
                          foo();
                          auto x = FOO;
                      }
                  });

        shouldCompile("main.d", "dstep.d");
    }
}

@("function parameter of elaborate type")
@safe unittest {
    with(immutable IncludeSandbox()) {
        expand(Out("dstep.d"), In("dstep.h"),
               q{
                   struct foo_t { int i; };
                   void bar(const struct foo_t *foo);
               });

        writeFile("main.d",
                  q{
                      import dstep;
                      void main() {
                          auto f = struct_foo_t(42);
                          bar(&f);
                          const cf = const struct_foo_t(33);
                          bar(&cf);
                      }
                  });

        shouldCompile("main.d", "dstep.d");
    }
}
