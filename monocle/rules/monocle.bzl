"""Monocle rules"""

ImageInfo = provider(
    "Image info",
    fields = {
        "name": "name",
        "tool": "tool",
    },
)

def _image_impl(ctx):
    runfile = ctx.actions.declare_file(ctx.label.name)
    tools = depset([], transitive = [dep[DefaultInfo].default_runfiles.files for dep in ctx.attr.deps])
    ctx.actions.run_shell(
        mnemonic = "Monocle",
        use_default_shell_env = True,
        tools = tools,
        inputs = [ctx.file.dockerfile] + ctx.files.srcs,
        arguments = [
            ctx.label.name,
            ctx.attr.tool,
            ctx.file.dockerfile.path,
            ctx.file.dockerfile.dirname,
            runfile.path,
        ],
        outputs = [runfile],
        command = "ID=$($2 build -q -t $1 -f $3 $4) && echo \"#!/bin/bash\n$2 create -v ./:/$1 \\$@ $ID /bin/bash -c 'sleep 60; while [ \\$(cat /proc/loadavg | cut -d \\\" \\\" -s -f1) != 0.00 ]; do sleep 60; done'\" > $5",
    )
    return [DefaultInfo(executable = runfile), ImageInfo(name = ctx.label.name, tool = ctx.attr.tool)]

image = rule(
    implementation = _image_impl,
    executable = True,
    attrs = {
        "tool": attr.string(default = "docker"),
        "dockerfile": attr.label(mandatory = True, allow_single_file = True),
        "srcs": attr.label_list(allow_files = True),
        "deps": attr.label_list(providers = [ImageInfo]),
    },
)

def _container_impl(ctx):
    exec = ctx.actions.declare_file(ctx.label.name)
    ctx.actions.run_shell(
        mnemonic = "Monocle",
        use_default_shell_env = True,
        tools = [ctx.file.image],
        inputs = [],
        arguments = [
            ctx.label.name,
            ctx.file.image.path,
            ctx.attr.image[ImageInfo].name,
            ctx.attr.image[ImageInfo].tool,
            ctx.attr.options,
            ctx.attr.binary,
            exec.path,
        ],
        outputs = [exec],
        command = "ID=$($2 $5) && echo \"#!/bin/bash\n$4 start $ID; $4 exec $ID $6 \\$@\" > $7",
    )
    return [DefaultInfo(executable = exec)]

container = rule(
    implementation = _container_impl,
    executable = True,
    attrs = {
        "image": attr.label(allow_single_file = True, mandatory = True, providers = [DefaultInfo, ImageInfo]),
        "options": attr.string(default = '', mandatory = False),
        "binary": attr.string(default = '', mandatory = False),
    },
)

def _tool_impl(name, visibility, **kwargs):
    container(
        name = name,
        visibility = visibility,
        **kwargs,
    )

tool = macro(
    implementation = _tool_impl,
    inherit_attrs = container,
    attrs = {
        "binary": attr.string(mandatory = True),
    },
)
