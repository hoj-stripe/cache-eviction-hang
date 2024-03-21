genrule(
    name = "fill_file_1kb",
    outs = ["file_1kb"],
    cmd = "head -c 1024 </dev/zero >$@",
    tags = ["manual"],
)

genrule(
    name = "copy_file_1kb",
    srcs = ["file_1kb"],
    outs = ["copied_file_1kb"],
    cmd = "cat $(SRCS) > $@",
    tags = ["manual"],
)

[genrule(name="target_%d" % num, outs=["file_%d" % num], cmd = "echo %d >$@" % num) for num in range(10)]

genrule(
    name = "all_files",
    srcs = ["file_%d" % num for num in range(10)],
    outs = ["example_file"],
    cmd = "cat $(SRCS) > $@",
    tags = ["manual"],
)
