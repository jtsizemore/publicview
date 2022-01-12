import os
import yaml
import time
import typing
import paramiko
import contextlib
import concurrent.futures as cfut


# NOTICE: these constant values seem to work well
#
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
FILE_EXTENSION = "txt"


def load_yaml(input_file: str) -> dict:
    """
    Read YAML file fully qualified path (fqp); output python object.
    """
    with open(input_file) as f:
        output = f.read()
        yaml_obj = yaml.safe_load(output)
    return yaml_obj


def create_list(input_list: list) -> list:
    """
    Create list of lists from YAML object.

    This outter list will be supplied to thread pool map.
    Pool supplies inner list to ssh_connection function.
    """
    arg_list = []
    for d in input_list:
        for h in d['target_host']:
            tmp_list = []
            tmp_list.append(d['host_type'])
            tmp_list.append(d['ssh_connection_mode'])
            tmp_list.append(h)
            tmp_list.append(d['cmd_string'])
            arg_list.append(tmp_list)
    return arg_list


@contextlib.contextmanager
def ssh_connect(ssh_client: typing.Callable[[], typing.Any], input_list: list) -> dict:
    """
    Custom context mgr. to manage paramiko ssh client connection.
    """
    d = {}
    host_type, ssh_connection_mode, target_host, cmd_str = input_list
    ssh_client.connect(
        hostname=target_host, port=SSH_PORT, username=os.getenv('LOGIN_USERNAME'),
        password=os.getenv('LOGIN_PASSWORD'), timeout=TCP_TIMEOUT
    )
    if ssh_connection_mode.lower() == "exec_command":
        try:
            stdin, stdout, stderr = ssh_client.exec_command(cmd_str)
            time.sleep(WAIT_TIME)
            output = stdout.read()
            d[target_host] = output.decode(TEXT_ENCODING)
            yield d
        except Exception as ERROR:
            print(ERROR)
        finally:
            ssh_client.close()
    if ssh_connection_mode.lower() == "invoke_shell":
        output = []
        try:
            ssh_session = ssh_client.invoke_shell()
            ssh_session.settimeout(BLOCK_WAIT)
            if ssh_session.send_ready():
                ssh_session.send("\nterminal length 0\n")
            for cmd in cmd_str:
                if ssh_session.send_ready():
                    ssh_session.send(f'\n{cmd}\n')
                    time.sleep(round(WAIT_TIME/WAIT_DENOMINATOR, TIME_ROUND))
            if ssh_session.send_ready():
                ssh_session.send("\nexit\n")
            while ssh_session.recv_ready():
                o = ssh_session.recv(RECV_BYTES)
                time.sleep(WAIT_TIME)
                output.append(o.decode(TEXT_ENCODING))
            d[target_host] = "".join(output)
            yield d
        except Exception as ERROR:
            print(ERROR)
        finally:
            while not ssh_session.closed:
                print(f'Client is Closed: {ssh_session.closed}')
                time.sleep(CLOSE_WAIT)
            print(f'Client is Closed: {ssh_session.closed}')
            ssh_client.close()


def cli_connect(input_list: list) -> typing.Callable[[], typing.Any]:
    """
    SSH connection func that calls custom context mgr.
    """
    ssh_client = paramiko.SSHClient()
    ssh_client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    with ssh_connect(ssh_client, input_list) as s:
        return s


def ssh_thread_pool_map(
    func1: typing.Callable[[], typing.Any],
    func2: typing.Callable[[], typing.Any], input_list: list) -> None:
    """
    Thread pool map for ssh connection.
    """
    with cfut.ThreadPoolExecutor(max_workers=MAX_THREADS) as p:
        results = p.map(func1, input_list)
        p.map(func2, results)


def write_file(result_dict: dict) -> None:
    """
    Write dict to file.
    """
    for k, v in result_dict.items():
        with open(f'{k}.{FILE_EXTENSION}', FILE_MODE) as f:
            f.write(v)
    return



if __name__ == "__main__":
    y = load_yaml("test.yaml")
    l = create_list(y)

    start_time = time.perf_counter()
    ssh_thread_pool_map(cli_connect, write_file, l)

    elapsed_time = time.perf_counter() - start_time

    print(f'Elapsed Time: {round(elapsed_time, TIME_ROUND)} seconds')