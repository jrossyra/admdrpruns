#!/usr/bin/env/ python


from argparse import ArgumentParser


def argparser():

    parser = ArgumentParser(description="Create admd jobs")

    parser.add_argument("project_name",
        help="Name of project")

    parser.add_argument("system_name",
        help="Name of system")

    parser.add_argument("--init_only",
        help="Only initialize project",
        action="store_true")

    parser.add_argument("-N","--n-trajectory", dest="n_traj",
        help="Number of trajectories to create",
        type=int, default=16)

    parser.add_argument("-M","--model", dest="model",
        help="Create a model each iteration",
        action='store_true')

    parser.add_argument("-x","--n-extension", dest="n_ext",
        help="Number of extensions to trajectories",
        type=int, default=1)

    parser.add_argument("--longts", dest="longts",
        help="Flag for 5fs timesteps",
        action='store_true')

    parser.add_argument("-l","--length",
        help="Length of trajectory segments in frames",
        type=int, default=100)

    parser.add_argument("-b","--n_rounds",
        help="Number of task rounds inside a single PBS job",
        type=int, default=0)

    parser.add_argument("-k","--minlength",
        help="Minimum trajectory total length in frames",
        type=int, default=300)

    parser.add_argument("-f","--fixedlength",
        help="Default randomizes traj length, flag to fix to n_steps",
        action='store_true')

    parser.add_argument("-R","--randomly",
        help="Purely random sampling",
        action='store_true')

    parser.add_argument("-p","--protein-stride", dest="prot",
        help="Stride between saved protein structure frames",
        type=int, default=5)

    parser.add_argument("-m","--master-stride", dest="all",
        help="Stride between saved frames with all atoms",
        type=int, default=20)

    parser.add_argument("-P","--platform",
        help="Simulation Platform: Reference, CPU, CUDA, or OpenCL",
        type=str, default="CPU")

    parser.add_argument("-d","--dblocation",
        help="IP address of MongoDB host",
        type=str, default="localhost")

    parser.add_argument("-r","--strategy",
        help="Filename of strategy script to run for generating tasks",
        type=str, default="run_admd.py")

    parser.add_argument("-i","--template", dest="template",
        help="Input job template file, ie admd_workers.pbs",
        type=str, default="run_admdrp.sh")

    return parser