#!/usr/bin/env python
"""
Generate a header file defining a number of levels of a macro
variadic argument FOR_EACH set.

Adapted from StackOverflow article:
  http://stackoverflow.com/questions/1872220/is-it-possible-to-iterate-over-arguments-in-variadic-macros

Defined FOR_EACH macro applies a unary functon ``f'' in order to the given
arguments. The maximum number of arguments is defined when calling this script
and is then statically constrained when used in C/C++.

"""

def generate_foreach_macro_header(N, output_path):
    lines = []
    lines.extend([
        "#ifndef FOR_EACH_MACRO_H_",
        "#define FOR_EACH_MACRO_H_",
        "",
        "#define CONCATENATE(arg1, arg2)   CONCATENATE1(arg1, arg2)",
        "#define CONCATENATE1(arg1, arg2)  arg1##arg2",
        "",
        "#define FOR_EACH_RSEQ_N() " + ', '.join(str(n) for n in range(N, -1, -1)),
        "#define FOR_EACH_ARG_N(" + ', '.join('_%d' % n for n in range(1, N+1)) + ", N, ...) N",
        "#define FOR_EACH_NARG_(...) FOR_EACH_ARG_N(__VA_ARGS__)",
        "#define FOR_EACH_NARG(...) FOR_EACH_NARG_(__VA_ARGS__, FOR_EACH_RSEQ_N())",
        ""
    ])

    # generating numbered for-each macros
    # TODO: Add zero arg version that throws an exception?
    lines.append(
        "#define FOR_EACH_1(f, x, ...) f(x)"
    )
    for i in range(2, N+1):
        lines.append(
            "#define FOR_EACH_%d(f, x, ...) f(x); FOR_EACH_%d(f, __VA_ARGS__)"
            % (i, i-1)
        )

    # Base FOR_EACH shows requirement for at least one variable
    lines.extend([
        "",
        "#define FOR_EACH_(N, what, x, ...) CONCATENATE(FOR_EACH_, N)(what, x, __VA_ARGS__)",
        "#define FOR_EACH(what, x, ...) FOR_EACH_(FOR_EACH_NARG(x, __VA_ARGS__), what, x, __VA_ARGS__)",
        "",
        "#endif  // FOR_EACH_MACRO_H_"
    ])

    #print '\n'.join(lines)
    with open(output_path, 'w') as ofile:
        ofile.write('\n'.join(lines))


if __name__ == '__main__':
    import sys
    generate_foreach_macro_header(int(sys.argv[1]), sys.argv[2])
