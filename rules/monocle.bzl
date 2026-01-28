"""Monocle rules"""

ImageInfo = provider(
    "Image info",
    fields = {
        "name": "name",
        "tool": "tool",
    },
)

def _image_impl(ctx):
    run = ctx.actions.declare_file(ctx.label.name)
    ctx.actions.run_shell(
        mnemonic="Monocle",
        inputs = [ctx.file.dockerfile],
        arguments = [
            ctx.label.name,
            ctx.attr.tool,
            ctx.file.dockerfile.path,
            ctx.file.dockerfile.dirname,
            run.path,
        ],
        outputs = [run],
        command = "ID=$($2 build -q -t $1 -f $3 $4) && echo \"#!/bin/bash\n$2 create -v ./:/$1 \\$@ $ID /bin/bash -c 'sleep 60; while [ \\$(cat /proc/loadavg | cut -d \\\" \\\" -s -f1) != 0.00 ]; do sleep 60; done'\" > $5",
    )
    return [DefaultInfo(executable = run), ImageInfo(name = ctx.label.name, tool = ctx.attr.tool)]

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


# ContainerInfo = provider(
#     fields = {
#         "id": "Container ID",
#     },
# )

# def _monocle_container_impl(ctx):
#     # out = ctx.actions.declare_file(ctx.label.name)
#     # ctx.actions.write(
#     #     output = out,
#     #     content = "Hello {}!\n".format(ctx.attr.username),
#     # )
#     # return [DefaultInfo(files = depset([out]))]
#     return [ContainerInfo(id = "container_id_12345")]

# monocle_container = rule(
#     implementation = _monocle_container_impl,
#     attrs = {
#         "image": attr.label(providers = [ImageInfo], default = "//containers/monocle:monocle_image"),
#     }
# )




    # ctx.actions.run(
    #     # tools = [ctx.executable.docker],
    #     outputs = [run_container],
    #     executable = Label(":container_sh"),
    #     arguments = [run_container.path],
    # )
    # dockerfile = ctx.file.dockerfile
    # Here you would add the logic to build the container using the provided Dockerfile.
    # For demonstration purposes, we'll just return a dummy ContainerInfo.
    # ctx.actions.run_shell(
    #     # tools = [ctx.file.docker],
    #     # inputs = [dockerfile, ctx.executable.docker],
    #     outputs = [run_container],
    #     # arguments = [dockerfile.path],
    #     # executable = "docker" #ctx.executable.docker,
    #     # mnemonic = "ContainerBuild",
    #     # command = "echo Building container with Dockerfile: {}".format(dockerfile.path),
    #     # command = "docker image inspect %s -f {{.Id}} > '%s'" % ("monocle", run_container.path),
    #     # command = "exit -1",
    #     # command = "ID=$(docker image inspect {tag} -f {{{{.Id}}}}); if [ $? -ne 0 ]; then ID=$(docker build -t {tag} -f {dockerfile} {path}); fi; echo \"#!/bin/bash\n$ID\" > {run_container}".format(tag = ctx.label.name, dockerfile = ctx.file.dockerfile.path, path = ctx.file.dockerfile.dirname, run_container = run_container.path)
    #     # command = "echo {dockerfile} > {run_container}".format(dockerfile = ctx.file.dockerfile.path, run_container = run_container.path)
    #     command = "echo $(pwd) > {run_container}".format(run_container = run_container.path)
    # )
    # # ctx.actions.run(executable = "docker", outputs = [run_container],)
    # print("Container build action created: {}".format(run_container.path))
    # return [DefaultInfo(files = depset([run_container])), ImageInfo(id = run_container)]
