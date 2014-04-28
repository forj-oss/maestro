import argparse
import logging
import os
import sys
import yaml

logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)
# create file handler which logs even debug messages
fh = logging.FileHandler('transformation.log')
fh.setLevel(logging.DEBUG)
# create console handler with a higher log level
ch = logging.StreamHandler()
ch.setLevel(logging.ERROR)
# create formatter and add it to the handlers
formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
ch.setFormatter(formatter)
fh.setFormatter(formatter)
# add the handlers to logger
logger.addHandler(ch)
logger.addHandler(fh)


def finish(message):
    msg = "Leaving at {0}".format(message,)
    print(msg)
    sys.exit()


def log_debug(message):
    logger.debug(message)


def log_info(message):
    logger.info(message)


def log_warn(message):
    logger.warn(message)


def log_error(message):
    logger.error(message)


def log_critical(message):
    logger.critical(message)

# arguments (if needed)
parser = argparse.ArgumentParser(description='Transformation of yaml files into hiera data')
parser.add_argument('templates', nargs='+',
                    help='YAML files to be processed')
args = parser.parse_args()

templates = list()
if args.templates is not None:
    templates = args.templates


def load_input_yaml(template_list):

    values = dict()

    try:

        for template in template_list:
            with open(template, 'r') as f:
                try:
                    values.update(yaml.load(f))
                except yaml.YAMLError as reason:
                    log_error(repr(reason))

    except (IOError, Exception) as reason:
        log_error(repr(reason))
        finish("load_input_yaml")

    return values


def add_license_text(path_to_file):
    license_text = "license.txt"
    try:

        with open(path_to_file, 'a') as f:
            with open(license_text, 'r') as l:
                lines = l.readlines()
                for line in lines:
                    f.write(line)
                f.write("\n")

    except (IOError, Exception) as reason:
        log_error(repr(reason))
        finish("add_license_text")


def create_output_yaml_file(path_to_file):
    try:

        if os.path.isfile(path_to_file):
            # remove the old file
            os.remove(path_to_file)

            # create a new blank file
        open(path_to_file, 'w')

    except (OSError, Exception), reason:
        log_error(repr(reason))
        finish("create_output_yaml_file")


def get_servers(template_list):
    servers = list()
    yaml_data = load_input_yaml(template_list)

    try:

        for server in yaml_data["blueprint-deploy"]["servers"]:
            servers.append(server["name"])

    except (yaml.YAMLError, Exception) as reason:
        log_error(repr(reason))
        finish("get_servers")

    return servers


def create_output_folder(path):
    try:
        if not os.path.exists(path):
            os.makedirs(path)

    except (OSError, Exception) as reason:
        log_error(repr(reason))
        finish("create_output_folder")


def get_apps_from_server(server, template_list):
    apps = list()
    yaml_data = load_input_yaml(template_list)

    try:

        if yaml_data["blueprint-deploy"]["servers"]:
            items = yaml_data["blueprint-deploy"]["servers"]

            for item in items:
                for k, v in item.iteritems():
                    if v == server:
                        for i in item["applications"]:
                            for key, value in i.iteritems():
                                if key != "class_params":  # don't do this.
                                    apps.append(key)

    except (KeyError, Exception) as reason:
        log_error(repr(reason))
        finish("get_apps_from_server")

    return apps


def append_classes_to_yaml(path_to_file, apps):
    try:

        with open(path_to_file, 'a') as f:
            f.write("\n")
            data = {"classes": [apps]}
            f.write(yaml.dump(data, default_flow_style=False))
            f.write("\n")

    except (IOError, Exception) as reason:
        log_error(repr(reason))
        finish("append_classes_to_yaml")


def append_params_to_yaml(path_to_file, app, params):
    try:

        with open(path_to_file, 'a') as f:
            f.write("\n")
            for k, v in params.iteritems():
                output = "maestro::{0}::{1}: {2}".format(app, k, v,)
                f.write(output)
                f.write("\n")

    except (OSError, Exception) as reason:
        log_error(repr(reason))
        finish("append_params_to_yaml")


def get_class_params(path_to_file, app, template_list):
    yaml_data = load_input_yaml(template_list)
    temp_dict = dict()

    try:
        servers = yaml_data["blueprint"]["define"]["modules"]
        temp_key = ""
        for server in servers:
                if app in server:
                    for item in server["options"]:
                        for k, v in item.iteritems():
                            if v is None:
                                temp_dict[k] = None
                                temp_key = k
                            if k == "value":
                                if v == "ask" or v is None:
                                    temp_dict[temp_key] = ""
                                elif isinstance(v, list):
                                    # TODO: why is passing None
                                    temp_list = list()
                                    for i in v:
                                        temp_list.append(i)
                                    temp_dict[temp_key] = ', '.join(temp_list)
                                else:
                                    temp_dict[temp_key] = v

    except (KeyError, Exception), reason:
        log_error(repr(reason))
        finish("get_class_params")

    else:
        append_params_to_yaml(path_to_file, app, temp_dict)

    return temp_dict


def create_yaml_for_each_server(template_list, path):  # change this name
    servers = get_servers(template_list)
    create_output_folder(path)

    for server in servers:
        name = "{0}.yaml".format(server,)
        path_to_file = "{0}{1}".format(path, name,)
        create_output_yaml_file(path_to_file)
        add_license_text(path_to_file)
        apps = get_apps_from_server(server, template_list)
        append_classes_to_yaml(path_to_file, apps)
        for app in apps:
            get_class_params(path_to_file, app, template_list)


if __name__ == "__main__":
    log_info("Transformation starting")

    path_to_files = '/usr/lib/forj/'
    create_yaml_for_each_server(templates, path_to_files)

    log_info("Transformation finish")
