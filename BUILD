[genrule(name="target_%d" % num, outs=["file_%d" % num], cmd = "echo %d >$@" % num) for num in range(10)]

genrule(
    name = "all_files",
    srcs = ["file_%d" % num for num in range(10)],
    outs = ["example_file"],
    cmd = "cat $(SRCS) > $@",
    tags = ["manual"],
)

genrule(
    name = "less_than_eight_files",
    srcs = ["file_%d" % num for num in range(6)],
    outs = ["example_file_2"],
    cmd = "cat $(SRCS) > $@",
    tags = ["manual"],
)
