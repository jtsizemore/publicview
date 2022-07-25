from azure.identity import AzureCliCredential
from azure.mgmt.resource import ResourceManagementClient
from azure.mgmt.network import NetworkManagementClient
from azure.mgmt.compute import ComputeManagementClient
import os
import yaml
import typing
import getpass


generic_client_result_msg01 = 'Azure Resource Created !'
generic_client_result_msg02 = 'Resource Name: {0}\n'

# print msg
def print_result_msg(result_name: str):
    '''
    DOC string
    '''
    print(generic_client_result_msg01, generic_client_result_msg02.format(result_name), sep='\n')


# process yaml seed file
def create_yaml_parent_obj(yaml_input_file: str) -> dict[typing.Any]:
    '''
    DOC string
    '''
    # yaml_input_file = 'azure_provision_vm_seedfile_github.yaml'
    read_mode = 'r'
    with open(yaml_input_file, read_mode) as f:
        yaml_str = f.read()
    return yaml.safe_load(yaml_str)


# set azure subscription id to linux environment variable
def set_environment_var(yaml_parent_obj: dict[typing.Any]) -> None:
    '''
    DOC string

    *** NOTE_TO_SELF (edit out later) ***
    is it better to use env vars ?
    or is it easier and more efficient to simply pass the python dict around to the diff funcs ?
    would probly have to use timeit() to determine.
    '''
    os.environ['AZURE_SUBSCRIPTION_ID_LOCAL'] = yaml_parent_obj['subscription_id_local']
    os.environ['AZURE_SUBSCRIPTION_ID_REMOTE'] = yaml_parent_obj['subscription_id_remote']


# get username and password from user
def get_vm_login_credentials_interactive() -> None:
    '''
    DOC string
    '''
    vm_login_username = input('Username: ')
    vm_login_password_tmp = getpass.getpass('Password: ')
    os.environ['AZURE_VM_USERNAME'] = vm_login_username
    os.environ['AZURE_VM_PASSWORD'] = vm_login_password_tmp


# get subscription id from user
def get_subscrition_id_interactive() -> None:
    '''
    DOC string
    '''
    subscription_id = input('Subscription ID: ')
    os.environ['AZURE_SUBSCRIPTION_ID_LOCAL'] = subscription_id


# get azure cli credentials
def authenticate_azcli() -> typing.Callable[..., typing.Any]:
    '''
    DOC string
    '''
    azcli_authentication = AzureCliCredential()
    return azcli_authentication


# provision azure resource group
def create_update_rg(
    azcli_authentication: typing.Callable[..., typing.Any],
    rg_name: str,
    yaml_kwargs: dict[typing.Any]
    ) -> None:
    '''
    DOC string
    '''
    resource_client = ResourceManagementClient(
        azcli_authentication,
        os.getenv('AZURE_SUBSCRIPTION_ID_LOCAL')
    )
    result = resource_client.resource_groups.create_or_update(rg_name, yaml_kwargs)
    print_result_msg(result.name)



# provision azure vnet
def create_update_vnet(
    azcli_authentication: typing.Callable[..., typing.Any],
    rg_name: str,
    vnet_name: str,
    yaml_kwargs: dict[typing.Any]
    ) -> str:
    '''
    DOC string
    '''
    network_client = NetworkManagementClient(azcli_authentication, os.getenv('AZURE_SUBSCRIPTION_ID_LOCAL'))
    poller = network_client.virtual_networks.begin_create_or_update(rg_name, vnet_name, yaml_kwargs)
    result = poller.result()
    print_result_msg(result.name)
    return result.id


# provision azure subnet
def create_update_subnet(
    azcli_authentication: typing.Callable[..., typing.Any],
    rg_name: str,
    vnet_name: str,
    snet_name: str,
    yaml_kwargs: dict[typing.Any],
    ) -> str:
    '''
    DOC string
    '''
    network_client = NetworkManagementClient(azcli_authentication, os.getenv('AZURE_SUBSCRIPTION_ID_LOCAL'))
    poller = network_client.subnets.begin_create_or_update(rg_name, vnet_name, snet_name, yaml_kwargs)
    result = poller.result()
    print_result_msg(result.name)
    return result.id


# provision azure public ip
def create_update_public_ip(
    azcli_authentication: typing.Callable[..., typing.Any],
    rg_name: str,
    pip_name: str,
    yaml_kwargs: dict[str]
    ) -> str:
    '''
    DOC string
    '''
    network_client = NetworkManagementClient(azcli_authentication, os.getenv('AZURE_SUBSCRIPTION_ID_LOCAL'))
    poller = network_client.public_ip_addresses.begin_create_or_update(rg_name, pip_name, yaml_kwargs)
    result = poller.result()
    print_result_msg(result.name)
    return result.id


# provision vm nic
def create_update_vm_nic(
    azcli_authentication: typing.Callable[..., typing.Any],
    rg_name: str,
    nic_name: str,
    snet_id: str,
    yaml_kwargs: dict[typing.Any]
    ) -> str:
    '''
    DOC string
    '''
    network_client = NetworkManagementClient(azcli_authentication, os.getenv('AZURE_SUBSCRIPTION_ID_LOCAL'))
    # HARD CODING SOME STUFF FOR SAKE OF EXPEDIENCY... NEED TO MAKE IT MORE DYNAMIC LATER
    # tmp var for original snet id from yaml seed file
    _verify_snetid = yaml_kwargs['ip_configurations'][0]['subnet']['id']
    if _verify_snetid == None:
        yaml_kwargs['ip_configurations'][0]['subnet']['id'] = snet_id
    poller = network_client.network_interfaces.begin_create_or_update(rg_name, nic_name, yaml_kwargs)
    result = poller.result()
    print_result_msg(result.name)
    return result.id


# provision azure vm
def create_update_vm(
    azcli_authentication: typing.Callable[..., typing.Any],
    rg_name: str,
    vm_name: str,
    yaml_kwargs: dict[typing.Any]
    ) -> str:
    '''
    DOC string
    '''
    compute_client = ComputeManagementClient(azcli_authentication, os.getenv('AZURE_SUBSCRIPTION_ID_LOCAL'))
    poller = compute_client.virtual_machines.begin_create_or_update(rg_name, vm_name, yaml_kwargs)
    result = poller.result()
    print_result_msg(result)


# main function
def main(yaml_input_file: str) -> None:
    '''
    DOC string
    '''
    azure_cli_authentication_precheck_msg = (
        'You must be authenticated via Azure CLI.\n\n'
    )
    azure_cli_authentication_user_input_msg = (
        '''Press ENTER if you have logged into Azure CLI and are ready to continue.
Otherwise, press CTRL-C to quit: '''
    )
    print(f'{azure_cli_authentication_precheck_msg}')
    user_input = input(f'{azure_cli_authentication_user_input_msg}')

    if user_input == '':
        # init
        get_subscrition_id_interactive()
        yaml_parent_object = create_yaml_parent_obj(yaml_input_file)
        azcli_authentication = authenticate_azcli()

        # check rg
        if yaml_parent_object['create_rg'] == True:
            create_update_rg(
                azcli_authentication,
                yaml_parent_object['resource_group']['name'],
                yaml_parent_object['resource_group']['kwargs']
                )
        input('enter')
        # check vnet
        if yaml_parent_object['create_vnet'] == True:
            vnet_id = create_update_vnet(
                azcli_authentication,
                yaml_parent_object['virtual_network']['rg_name'],
                yaml_parent_object['virtual_network']['name'],
                yaml_parent_object['virtual_network']['kwargs']
                )
            snet_id = create_update_subnet(
                azcli_authentication,
                yaml_parent_object['subnet']['rg_name'],
                yaml_parent_object['subnet']['vnet_name'],
                yaml_parent_object['subnet']['name'],
                yaml_parent_object['subnet']['kwargs']
                )
            print(f'VNET ID: {vnet_id}')
            print(f'SNET ID: {snet_id}')
            
        input('enter')
        # loop through vms
        for vm in yaml_parent_object['create_vm']:
            #  HARD CODING SOME STUFF FOR SAKE OF EXPEDIENCY... NEED TO MAKE IT MORE DYNAMIC LATER
            # public ip check
            # if len(vm['public_ip_address']) < 1:
            #     pip_id = create_update_public_ip(
            #         azcli_authentication,
            #         vm['public_ip_address']['rg_name'],
            #         vm['public_ip_address']['name'],
            #         vm['public_ip_address']['kwargs']
            #         )
            input('enter')
            # subnet check
            _tmp_subnet = vm['vm_nic']['kwargs']['ip_configurations'][0]['subnet']
            if _tmp_subnet['id'] is None:
                _tmp_subnet['id'] = snet_id
            # create nic
            if _tmp_subnet['public_ip_address']['id'] is None:
                _tmp_subnet['public_ip_address']['id'] = pip_id
            nic_id = create_update_vm_nic(
                azcli_authentication,
                vm['vm_nic']['rg_name'],
                vm['vm_nic']['name'],
                snet_id,
                vm['vm_nic']['kwargs']
            )
            input('enter')
            # admin password
            _tmp_osprofile = vm['azure_vm']['kwargs']['os_profile']
            if _tmp_osprofile['admin_password'] is None:
                get_vm_login_credentials_interactive()
                _tmp_osprofile['admin_password'] = os.getenv('AZURE_VM_PASSWORD')
            # check nic association
            _tmp_networkinterfaces = vm['azure_vm']['kwargs']['network_profile']['network_interfaces']
            if len(_tmp_networkinterfaces) < 1:
                _tmp_networkinterfaces.append({'id': nic_id})
            # provision vm
            rg_name = yaml_parent_object['resource_group']['name']
            vm_name = vm['azure_vm']['name']
            kwargs = vm['azure_vm']['kwargs']
            create_update_vm(
                azcli_authentication,
                rg_name,
                vm_name,
                kwargs
                )
            input('enter')


# if __name__ == '__main__':
#     main()
