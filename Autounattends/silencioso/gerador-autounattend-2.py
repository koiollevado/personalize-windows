import xml.etree.ElementTree as ET
from xml.dom import minidom
import random
import string
from datetime import datetime


def prettify(elem):
    """Gera XML formatado com declaração utf-8"""
    rough_string = ET.tostring(elem, 'utf-8')
    reparsed = minidom.parseString(rough_string)
    pretty_xml = reparsed.toprettyxml(indent="    ")
    pretty_xml = pretty_xml.replace('<?xml version="1.0" ?>', 
                                    '<?xml version="1.0" encoding="utf-8"?>')
    return pretty_xml


def gb_to_mb(gb_str):
    if not gb_str:
        return ""
    try:
        return str(int(float(gb_str) * 1024))
    except:
        return ""


def gerar_nome_computador():
    suffix = ''.join(random.choices(string.ascii_uppercase + string.digits, k=4))
    return f"PC-{suffix}"


def gerar_nome_usuario():
    letters = ''.join(random.choices(string.ascii_uppercase, k=2))
    numbers = ''.join(random.choices(string.digits, k=2))
    return f"User-{letters}{numbers}"


def get_input(prompt, default=None):
    if default:
        value = input(f"{prompt} [{default}]: ").strip()
        return value if value else default
    value = input(f"{prompt}: ").strip()
    return value if value else None


def coletar_configuracoes():
    print("=" * 80)
    print("   GERADOR DE AUTO UNATTEND.XML - WINDOWS 10 PT-BR")
    print("=" * 80)

    username = get_input("Nome do usuário (Enter = automático)", None) or gerar_nome_usuario()
    
    organization_default = f"{username} Ltda"
    organization = get_input("Organização / Empresa", organization_default)

    computer_default = gerar_nome_computador()
    computername = get_input("Nome do computador (Enter = automático)", computer_default)

    password = get_input("Senha (Enter = sem senha)", None) or ""

    arch_choice = get_input("\nArquitetura (1=amd64 / 2=x86)", "1")
    architecture = "amd64" if arch_choice == "1" else "x86"

    part_choice = get_input("Particionamento (1=MBR / 2=GPT)", "2")
    is_mbr = part_choice == "1"

    print("\n=== CONFIGURAÇÃO DE PARTIÇÕES ===")
    partitions = []
    has_recovery = False

    if is_mbr:
        partitions.append({"order": "1", "type": "Primary", "size": "100", "size_gb": "0.1",
                           "label": "System", "letter": "S", "active": "true"})
        win_gb = get_input("Tamanho da partição Windows (GB) - Enter = restante", "")
        win_mb = gb_to_mb(win_gb)
        partitions.append({"order": "2", "type": "Primary", "size": win_mb, "size_gb": win_gb or "Restante",
                           "label": "Windows", "letter": "C"})
    else:
        partitions.append({"order": "1", "type": "EFI", "size": "260", "size_gb": "0.26",
                           "label": "EFI", "letter": "S", "format": "FAT32"})
        partitions.append({"order": "2", "type": "MSR", "size": "16", "size_gb": "0.016", "label": "MSR"})

        win_gb = get_input("Tamanho da partição Windows (GB) - Enter = restante", "")
        win_mb = gb_to_mb(win_gb)
        partitions.append({"order": "3", "type": "Primary", "size": win_mb, "size_gb": win_gb or "Restante",
                           "label": "Windows", "letter": "C"})

    # Recovery 450MB
    if get_input("Criar partição Recovery (450MB)? (S/n)", "s").lower() != "n":
        has_recovery = True
        if is_mbr:
            partitions.append({"order": str(len(partitions)+1), "type": "Primary", "size": "450",
                               "size_gb": "0.45", "label": "Recovery", "letter": "R", "typeid": "0x27"})
        else:
            partitions.append({"order": str(len(partitions)+1), "type": "Primary", "size": "450",
                               "size_gb": "0.45", "label": "Recovery", "letter": "R",
                               "typeid": "DE94BBA4-06D1-4D40-A16A-BFD50179D6AC",
                               "gpt_attributes": "0x8000000000000001"})

    # Dados
    if get_input("Criar partição de Dados (resto do disco)? (S/n)", "s").lower() != "n":
        partitions.append({"order": str(len(partitions)+1), "type": "Primary", "size": "",
                           "size_gb": "Restante", "label": "Dados", "letter": "D"})

    # Edição
    print("\nEdições do Windows 10:")
    print("1. Home")
    print("2. Home Single Language")
    print("3. Pro     ← recomendado")
    print("4. Enterprise")
    ed = get_input("Escolha a edição", "3")

    editions = {
        "1": ("Windows 10 Home", "TX9XD-98N7V-6WMQ6-BX7FG-H8Q99"),
        "2": ("Windows 10 Home Single Language", "7HNRX-D94MR-C4W2Y-R9V7M-8V2XJ"),
        "3": ("Windows 10 Pro", "VK7JG-NPHTM-C97JM-9MPGT-3V66T"),
        "4": ("Windows 10 Enterprise", "NPPR9-FWDCX-D2C8J-H872K-2YT43")
    }
    edition_name, product_key = editions.get(ed, editions["3"])

    return {
        'username': username,
        'password': password,
        'computername': computername,
        'organization': organization,
        'architecture': architecture,
        'is_mbr': is_mbr,
        'edition_name': edition_name,
        'product_key': product_key,
        'partitions': partitions,
        'has_recovery': has_recovery
    }


def generate_autounattend(config):
    """Gera o XML completo"""
    unattend = ET.Element('unattend', {
        'xmlns': 'urn:schemas-microsoft-com:unattend',
        'xmlns:wcm': 'http://schemas.microsoft.com/WMIConfig/2002/State',
        'xmlns:xsi': 'http://www.w3.org/2001/XMLSchema-instance'
    })

    def create_component(parent, name):
        attrib = {
            'name': name,
            'processorArchitecture': config['architecture'],
            'publicKeyToken': '31bf3856ad364e35',
            'language': 'neutral',
            'versionScope': 'nonSxS'
        }
        return ET.SubElement(parent, 'component', attrib)

    # ====================== windowsPE ======================
    settings_pe = ET.SubElement(unattend, 'settings', {'pass': 'windowsPE'})

    intl_winpe = create_component(settings_pe, 'Microsoft-Windows-International-Core-WinPE')
    setup_ui = ET.SubElement(intl_winpe, 'SetupUILanguage')
    ET.SubElement(setup_ui, 'UILanguage').text = 'pt-BR'

    for tag in ['InputLocale', 'SystemLocale', 'UILanguage', 'UserLocale']:
        ET.SubElement(intl_winpe, tag).text = 'pt-BR'
    ET.SubElement(intl_winpe, 'UILanguageFallback').text = 'pt-BR'

    setup = create_component(settings_pe, 'Microsoft-Windows-Setup')

    # DiskConfiguration
    disk_config = ET.SubElement(setup, 'DiskConfiguration')
    disk = ET.SubElement(disk_config, 'Disk', {'wcm:action': 'add'})
    ET.SubElement(disk, 'DiskID').text = '0'
    ET.SubElement(disk, 'WillWipeDisk').text = 'true'

    create_parts = ET.SubElement(disk, 'CreatePartitions')
    modify_parts = ET.SubElement(disk, 'ModifyPartitions')

    install_partition_id = None

    for idx, p in enumerate(config['partitions'], 1):
        cp = ET.SubElement(create_parts, 'CreatePartition', {'wcm:action': 'add'})
        ET.SubElement(cp, 'Order').text = p['order']
        ET.SubElement(cp, 'Type').text = p['type']
        if p.get('size'):
            ET.SubElement(cp, 'Size').text = p['size']
        else:
            ET.SubElement(cp, 'Extend').text = 'true'

        mp = ET.SubElement(modify_parts, 'ModifyPartition', {'wcm:action': 'add'})
        ET.SubElement(mp, 'Order').text = p['order']
        ET.SubElement(mp, 'PartitionID').text = str(idx)
        ET.SubElement(mp, 'Format').text = p.get('format', 'NTFS')
        ET.SubElement(mp, 'Label').text = p['label']
        
        if p.get('letter'):
            ET.SubElement(mp, 'Letter').text = p['letter']
        if p.get('active'):
            ET.SubElement(mp, 'Active').text = p['active']
        if p.get('typeid'):
            ET.SubElement(mp, 'TypeID').text = p['typeid']
        if p.get('gpt_attributes'):
            ET.SubElement(mp, 'GPTAttributes').text = p['gpt_attributes']

        if p['label'] == "Windows":
            install_partition_id = str(idx)

    ET.SubElement(disk_config, 'WillShowUI').text = 'OnError'

    # ImageInstall + UserData
    image_install = ET.SubElement(setup, 'ImageInstall')
    os_image = ET.SubElement(image_install, 'OSImage')

    install_from = ET.SubElement(os_image, 'InstallFrom')
    meta = ET.SubElement(install_from, 'MetaData', {'wcm:action': 'add'})
    ET.SubElement(meta, 'Key').text = '/IMAGE/NAME'
    ET.SubElement(meta, 'Value').text = config['edition_name']

    install_to = ET.SubElement(os_image, 'InstallTo')
    ET.SubElement(install_to, 'DiskID').text = '0'
    ET.SubElement(install_to, 'PartitionID').text = install_partition_id

    ET.SubElement(os_image, 'WillShowUI').text = 'OnError'

    user_data = ET.SubElement(setup, 'UserData')
    product_key = ET.SubElement(user_data, 'ProductKey')
    ET.SubElement(product_key, 'Key').text = config['product_key']
    ET.SubElement(product_key, 'WillShowUI').text = 'OnError'
    ET.SubElement(user_data, 'AcceptEula').text = 'true'

    ET.SubElement(setup, 'UseConfigurationSet').text = 'false'

    # ====================== SPECIALIZE ======================
    settings_spec = ET.SubElement(unattend, 'settings', {'pass': 'specialize'})
    deploy = create_component(settings_spec, 'Microsoft-Windows-Deployment')
    run_sync = ET.SubElement(deploy, 'RunSynchronous')

    commands = [
        "net.exe accounts /maxpwage:UNLIMITED",
        'reg.exe add "HKLM\\SYSTEM\\CurrentControlSet\\Control\\FileSystem" /v LongPathsEnabled /t REG_DWORD /d 1 /f',
        'reg.exe add "HKLM\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\OOBE" /v BypassNRO /t REG_DWORD /d 1 /f',
        'reg.exe add "HKLM\\SYSTEM\\CurrentControlSet\\Control\\BitLocker" /v "PreventDeviceEncryption" /t REG_DWORD /d 1 /f',
    ]

    # Adiciona comando do Recovery se a partição existir
    if config.get('has_recovery'):
        commands.append(r'cmd /c "reagentc /disable & reagentc /setreimage /path R:\Recovery\WindowsRE /target C:\Windows & reagentc /enable"')

    for order, path in enumerate(commands, 1):
        cmd = ET.SubElement(run_sync, 'RunSynchronousCommand', {'wcm:action': 'add'})
        ET.SubElement(cmd, 'Order').text = str(order)
        ET.SubElement(cmd, 'Path').text = path
        if "reagentc" in path:
            ET.SubElement(cmd, 'Description').text = "Configurar Windows Recovery Environment"

    # ====================== oobeSystem ======================
    settings_oobe = ET.SubElement(unattend, 'settings', {'pass': 'oobeSystem'})

    intl_oobe = create_component(settings_oobe, 'Microsoft-Windows-International-Core')
    for tag in ['InputLocale', 'SystemLocale', 'UILanguage', 'UserLocale']:
        ET.SubElement(intl_oobe, tag).text = 'pt-BR'
    ET.SubElement(intl_oobe, 'UILanguageFallback').text = 'pt-BR'

    shell = create_component(settings_oobe, 'Microsoft-Windows-Shell-Setup')

    if config.get('password'):
        auto = ET.SubElement(shell, 'AutoLogon')
        pwd = ET.SubElement(auto, 'Password')
        ET.SubElement(pwd, 'Value').text = config['password']
        ET.SubElement(pwd, 'PlainText').text = 'true'
        ET.SubElement(auto, 'Enabled').text = 'true'
        ET.SubElement(auto, 'Username').text = config['username']
        ET.SubElement(auto, 'LogonCount').text = '1'

    ET.SubElement(shell, 'ComputerName').text = config['computername']
    ET.SubElement(shell, 'RegisteredOrganization').text = config.get('organization', '')
    ET.SubElement(shell, 'RegisteredOwner').text = config['username']

    oobe = ET.SubElement(shell, 'OOBE')
    for k, v in {
        'HideEULAPage': 'true',
        'HideOEMRegistrationScreen': 'true',
        'HideOnlineAccountScreens': 'true',
        'HideWirelessSetupInOOBE': 'true',
        'NetworkLocation': 'Work',
        'ProtectYourPC': '3'
    }.items():
        ET.SubElement(oobe, k).text = v

    # Conta Local
    local_acc = ET.SubElement(
        ET.SubElement(ET.SubElement(shell, 'UserAccounts'), 'LocalAccounts'),
        'LocalAccount', {'wcm:action': 'add'}
    )
    ET.SubElement(local_acc, 'Name').text = config['username']
    ET.SubElement(local_acc, 'DisplayName').text = config['username']
    ET.SubElement(local_acc, 'Group').text = 'Administrators'
    
    if config.get('password'):
        pwd_elem = ET.SubElement(local_acc, 'Password')
        ET.SubElement(pwd_elem, 'Value').text = config['password']
        ET.SubElement(pwd_elem, 'PlainText').text = 'true'

    return unattend


def main():
    config = coletar_configuracoes()

    print("\n" + "="*90)
    print("RESUMO DA CONFIGURAÇÃO")
    print("="*90)
    print(f"Usuário          : {config['username']}")
    print(f"Empresa          : {config['organization']}")
    print(f"Computador       : {config['computername']}")
    print(f"Edição           : {config['edition_name']}")
    print(f"Arquitetura      : {config['architecture']}")
    print(f"Recovery         : {'Sim' if config.get('has_recovery') else 'Não'}")

    print("\nPartições:")
    for p in config['partitions']:
        print(f"  • {p['label']:12} | Letra: {p.get('letter','N/A')} | Tamanho: {p.get('size_gb','Restante')}")

    if input("\nConfirmar e gerar autounattend.xml? (S/n): ").strip().lower() in ['n', 'no']:
        print("Operação cancelada.")
        return

    xml_tree = generate_autounattend(config)
    timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    filename = f"autounattend-{timestamp}.xml"

    with open(filename, 'w', encoding='utf-8') as f:
        f.write(prettify(xml_tree))

    print(f"\n✅ Arquivo gerado com sucesso: {filename}")


if __name__ == "__main__":
    random.seed()
    main()
