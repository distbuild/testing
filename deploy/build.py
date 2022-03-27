#! /usr/bin/env python3

"""Reads in the Jinja2 templates for the docker-compose yaml files, and populates them
with the values from matrix.yml."""

import argparse
import sys

from collections import namedtuple
from jinja2 import Environment, FileSystemLoader
from pathlib import Path
from ruamel.yaml import YAML

DEFAULT_OUTPUT_DIR = "./"
DEFAULT_MATRIX_FILE = "./matrix.yml"

Project = namedtuple(
    "Project",
    ["template_filename", "output_filename_path", "output_path", "version_refs"],
)


def get_matrix(matrix_path):
    """Read the file at matrix_path, and return the parsed yaml dictionary"""
    yaml = YAML(typ="safe")
    with matrix_path.open(mode="r") as input_stream:
        matrix_yaml = yaml.load(input_stream)
    return matrix_yaml


def main(args):
    """Reads in the Jinja2 templates for the docker-compose yaml files, and populates
    them with the values from matrix.yml."""
    matrix_yaml = get_matrix(args.matrix_path)

    # The templates directory is defined in matrix.yml, and is relative to matrix.yml
    templates_relative_path = Path(matrix_yaml["templates_dir"])
    templates_path = args.matrix_path.parent.joinpath(templates_relative_path)
    template_env = Environment(loader=FileSystemLoader(str(templates_path)))

    project_list = []
    for docker_file in matrix_yaml["projects"].values():
        template_filename = docker_file["filename"]
        output_filename_path = Path(template_filename).with_suffix(".yml")
        project_list.append(
            Project(
                template_filename=template_filename,
                output_filename_path=output_filename_path,
                output_path=args.output_dir.joinpath(output_filename_path),
                version_refs={
                    ref_name: ref_dict["value"]
                    for ref_name, ref_dict in docker_file["version_refs"].items()
                },
            )
        )

    if not args.force:
        existing_filepaths = [
            project.output_path
            for project in project_list
            if project.output_path.exists()
        ]
        if existing_filepaths:
            print("Unable to create output files, some of the files already exist:")
            print("\n".join([f"    {filepath}" for filepath in existing_filepaths]))
            print(
                "Aborting Script. No new files created. No files overwritten."
                "\n(See help text for the option to overwrite existing files.)"
            )
            sys.exit(1)

    for project in project_list:
        template = template_env.get_template(project.template_filename)
        with project.output_path.open(mode="w") as output_stream:
            output_stream.write(template.render(project.version_refs) + "\n")
        if args.print_filenames:
            if args.verbose:
                template_path = templates_path.joinpath(Path(project.template_filename))
                output_string = (
                    f"Creating: {project.output_path}\nFrom    : {template_path}\n"
                )
                output_string += "\n".join(
                    [f"    {var}: \t{val}" for var, val in project.version_refs.items()]
                )
                output_string += "\n"
            else:
                output_string = f"{project.output_path}"
            print(output_string, file=sys.stderr, flush=True)


def get_args():
    """Get commandline arguments"""
    arg_parser = argparse.ArgumentParser(description=__doc__)
    arg_parser.add_argument(
        "-o",
        "--output_dir",
        type=Path,
        default=DEFAULT_OUTPUT_DIR,
        help=(
            "Path to the directory in which to put the created docker-compose yaml"
            f" files. Defaults to '{DEFAULT_OUTPUT_DIR}'"
        ),
    )
    arg_parser.add_argument(
        "-m",
        "--matrix_file",
        default=DEFAULT_MATRIX_FILE,
        dest="matrix_path",
        type=Path,
        help=(
            "Path to the matrix file containing a list of all the docker-compose files"
            f" and the appropriate version refs. Defaults to '{DEFAULT_MATRIX_FILE}'"
        ),
    )
    arg_parser.add_argument(
        "-f",
        "--force",
        action="store_true",
        help="Overwrite existing docker-compose yaml files.",
    )
    verbosity_group = arg_parser.add_mutually_exclusive_group()
    verbosity_group.add_argument(
        "-q",
        "--quiet",
        action="store_false",
        dest="print_filenames",
        help=(
            "Suppress output. Without this, the script's default behaviour is to print"
            " the filename of each yaml file to stderr as it is created."
        ),
    )
    verbosity_group.add_argument(
        "-v",
        "--verbose",
        action="store_true",
        help=(
            "Prints a more detailed output to stderr for each yaml file,"
            " as it is created."
        ),
    )

    return arg_parser.parse_args()


if __name__ == "__main__":
    ARGS = get_args()
    main(ARGS)
