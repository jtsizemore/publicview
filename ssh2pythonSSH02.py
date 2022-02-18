import os
import yaml
import time
import socket
import contextlib
from ssh2.session import Session
import concurrent.futures as cfut


# max threads
MAX_THREADS = None
# SSH port
SSH_PORT = 22
# SSH client TCP timeout in seconds
TCP_TIMEOUT = 300
# SSH client receive amount in bytes
RECV_BYTES = 131070
# text encoding
TEXT_ENCODING = "utf-8"
# time in seconds for time.sleep()
WAIT_TIME = 1
# channel settimeout() in seconds
BLOCK_WAIT = 2
# WAIT_TIME denominator for math: WAIT_TIME/WAIT_DENOMINATOR
WAIT_DENOMINATOR = 100
# time interval btwn querying channel close status
CLOSE_WAIT = 0.5
# number of decimal places to round time
TIME_ROUND = 3
# file mode to be used with open(filename, mode)
FILE_MODE = "w"
# file extension to be used with writing files
FILE_EXTENSION = ".txt"


def load_yaml(input_file):
    """
    Read YAML file fully qualified path (fqp); output python object.
    """
    with open(input_file) as f:
        output = f.read()
        yaml_obj = yaml.safe_load(output)
    return yaml_obj


def create_list(input_list):
    """
    Create list of lists from YAML object.
    This outter list will be supplied to thread pool map.
    Pool supplies inner list to ssh_connection function.
    """
    arg_list = []
    for d in input_list:
        for h in d['target_host']:
            tmp_list = []
            tmp_list.append(h)
            tmp_list.append(d['cmd_string'])
            arg_list.append(tmp_list)
    return arg_list


def ssh_connect(input_list):
    """
    ssh2-python test implementation.
    """
    port = 22
    username = os.getenv('USER')
    password = os.getenv('LOGIN_PASSWORD')
    hostname, cmd_string = input_list

    output_dict = {}
    data_list = []

    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.connect((hostname, port))

        session = Session()
        session.handshake(sock)
        session.userauth_password(username, password)

        channel = session.open_session()
        channel.execute(cmd_string)
        size, data = channel.read()

        while size > 0:
            data_list.append(data.decode())
            size, data = channel.read()

        output_dict[hostname] = ''.join(data_list)
        return output_dict

    except Exception as ERROR:
        print(ERROR)
    finally:
        channel.close()


def write_file(input_dict):
    """
    Write output dict to file.
    """
    time_stamp = time.strftime("%Y%m%d%H%M")
    ns = str(time.time_ns())[-5:]
    for k, v in input_dict.items():
        with open(f'{k}-{time_stamp}-{ns}{FILE_EXTENSION}', FILE_MODE) as f:
            f.write(v)


def thread_pool_map(func1, func2, input_list):
    """
    Thread pool map for ssh connection and file write.
    """
    with cfut.ThreadPoolExecutor() as p:
        output_generator = p.map(func1, input_list)
        p.map(func2, output_generator)


if __name__ == '__main__':
    y = load_yaml("ssh2-python-test.yaml")
    l = create_list(y)

    start_time = time.perf_counter()

    thread_pool_map(ssh_connect, write_file, l)

    elapsed_time = time.perf_counter() - start_time
    print(f'Elapsed Time: {round(elapsed_time, TIME_ROUND)} seconds')