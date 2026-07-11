import xml.etree.ElementTree as ET
from xml.dom import minidom
import random
import string
from datetime import datetime

def prettify(elem):
    """Gera XML formatado com declaração correta (encoding utf-8)"""
    rough_string = ET.tostring(elem, 'utf-8')
    reparsed = minidom.parseString(rough_string)
    
    # Substitui a declaração padrão
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
    letters = ''.join(random.choices(string.ascii_lowercase, k=2))
    numbers = ''.join(random.choices(string.digits, k=2))
    return f"User-{letters}{numbers}"

def get_input(prompt, default=None):
    if default:
        value = input(f"{prompt} [{default}]: ").strip()
        return value if value else default
    else:
        value = input(f"{prompt}: ").strip()
        return value if value else None

def mostrar_resumo(config):
    print("\n" + "="*95)
    print(" " * 35 + "RESUMO DA CONFIGURAÇÃO")
    print("="*95)
    print(f"Usuário:".ljust(28) + config['username'])
    print(f"Senha:".ljust(28) + (config['password'] if config['password'] else "<sem senha>"))
    print(f"Computador:".ljust(28) + config['computername'])
    print(f"Organização:".ljust(28) + (config.get('organization') or "<vazio>"))
    print(f"Arquitetura:".ljust(28) + config['architecture'])
    print(f"Particionamento:".ljust(28) + ("MBR" if config['is_mbr'] else "GPT"))
    print(f"Edição:".ljust(28) + config['edition_name'])

    print("\nPartições (em GB):")
    for p in config['partitions']:
        size_display = p.get('size_gb', 'Restante')
        print(f"  • {p['label'].ljust(12)} | {p['type'].ljust(8)} | {size_display.ljust(10)} GB | Letra: {p.get('letter','N/A')}")

    print("="*95)
    return input("Confirmar e gerar arquivo? (S/n): ").strip().lower() not in ['n', 'no']

def main():
    print("=" * 75)
    print("   GERADOR AVANÇADO DE AUTO UNATTEND.XML - PT-BR")
    print("=" * 75)

    username = get_input("Nome do usuário (Enter = automático)", None) or gerar_nome_usuario()
    computername = get_input("Nome do computador (Enter = automático)", None) or gerar_nome_computador()

    organization_input = get_input("Organização", "MinhaEmpresa")
    organization = organization_input if organization_input != "MinhaEmpresa" else ""

    password = get_input("Senha (Enter = sem senha)", None) or ""

    arch_choice = get_input("\nArquitetura (1=amd64 / 2=x86)", "1")
    architecture = "amd64" if arch_choice == "1" else "x86"

    part_choice = get_input("Particionamento (1=MBR / 2=GPT)", "1")
    is_mbr = part_choice == "1"

    print("\n=== CONFIGURAÇÃO DE PARTIÇÕES (tamanhos em GB) ===")
    partitions = []
    has_recovery = False

    if is_mbr:
        partitions.append({"order":"1", "type":"Primary", "size":"100", "size_gb":"0.1", "label":"System", "letter":"S", "active":"true"})
        win_gb = get_input("Tamanho Windows (GB) - Enter = restante", "")
        win_mb = gb_to_mb(win_gb) if win_gb else ""
        partitions.append({"order":"2", "type":"Primary", "size":win_mb, "size_gb":win_gb or "Restante", "label":"Windows", "letter":"W"})

        if get_input("Incluir Recovery 450MB? (S/n)", "s").lower() != "n":
            has_recovery = True
            partitions.append({"order":str(len(partitions)+1), "type":"Primary", "size":"450", "size_gb":"0.45", "label":"Recovery", "letter":"R", "typeid":"0x27"})

        if get_input("Incluir Dados (restante)? (S/n)", "s").lower() != "n":
            order = str(len(partitions)+1)
            partitions.append({"order":order, "type":"Primary", "size":"", "size_gb":"Restante", "label":"Dados", "letter":"D"})
    else:
        partitions.append({"order":"1", "type":"EFI", "size":"100", "size_gb":"0.1", "label":"EFI", "letter":"S", "format":"FAT32"})
        partitions.append({"order":"2", "type":"MSR", "size":"16", "size_gb":"0.016", "label":"MSR"})

        win_gb = get_input("Tamanho Windows (GB) - Enter = restante", "")
        win_mb = gb_to_mb(win_gb) if win_gb else ""
        partitions.append({"order":"3", "type":"Primary", "size":win_mb, "size_gb":win_gb or "Restante", "label":"Windows", "letter":"W"})

        if get_input("Incluir Recovery 450MB? (S/n)", "s").lower() != "n":
            has_recovery = True
            order = str(len(partitions)+1)
            partitions.append({
                "order": order,
                "type":"Primary",
                "size":"450",
                "size_gb":"0.45",
                "label":"Recovery",
                "letter":"R",
                "typeid":"DE94BBA4-06D1-4D40-A16A-BFD50179D6AC",
                "gpt_attributes": "0x8000000000000001"
            })

        if get_input("Incluir Dados (restante)? (S/n)", "s").lower() != "n":
            order = str(len(partitions)+1)
            partitions.append({"order":order, "type":"Primary", "size":"", "size_gb":"Restante", "label":"Dados", "letter":"D"})

    # Edição
    print("\nEdição do Windows:")
    print("1.Home  2.Home SL  3.Pro  4.Enterprise")
    ed = get_input("Escolha", "3")
    editions = {
        "1": ("Windows 10 Home", "TX9XD-98N7V-6WMQ6-BX7FG-H8Q99"),
        "2": ("Windows 10 Home Single Language", "7HNRX-D94MR-C4W2Y-R9V7M-8V2XJ"),
        "3": ("Windows 10 Pro", "VK7JG-NPHTM-C97JM-9MPGT-3V66T"),
        "4": ("Windows 10 Enterprise", "NPPR9-FWDCX-D2C8J-H872K-2YT43")
    }
    edition_name, product_key = editions.get(ed, editions["3"])

    config = {
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

    if not mostrar_resumo(config):
        print("Operação cancelada.")
        return

    # ====================== GERAÇÃO DO XML ======================
    unattend = ET.Element('unattend', {
        'xmlns': 'urn:schemas-microsoft-com:unattend',
        'xmlns:wcm': 'http://schemas.microsoft.com/WMIConfig/2002/State',
        'xmlns:xsi': 'http://www.w3.org/2001/XMLSchema-instance'
    })

    def create_component(parent, name):
        attrib = {
            'name': name,
            'processorArchitecture': architecture,
            'publicKeyToken': '31bf3856ad364e35',
            'language': 'neutral',
            'versionScope': 'nonSxS'
        }
        if name in ['Microsoft-Windows-International-Core', 'Microsoft-Windows-Shell-Setup']:
            attrib['xmlns:xsi'] = 'http://www.w3.org/2001/XMLSchema-instance'
        return ET.SubElement(parent, 'component', attrib)

    # windowsPE
    settings_pe = ET.SubElement(unattend, 'settings', {'pass': 'windowsPE'})
    intl_winpe = create_component(settings_pe, 'Microsoft-Windows-International-Core-WinPE')
    sui = ET.SubElement(intl_winpe, 'SetupUILanguage')
    ET.SubElement(sui, 'UILanguage').text = 'pt-BR'
    ET.SubElement(intl_winpe, 'InputLocale').text = '0416:00010416'
    ET.SubElement(intl_winpe, 'SystemLocale').text = 'pt-BR'
    ET.SubElement(intl_winpe, 'UILanguage').text = 'pt-BR'
    ET.SubElement(intl_winpe, 'UILanguageFallback').text = 'pt-BR'
    ET.SubElement(intl_winpe, 'UserLocale').text = 'pt-BR'

    setup = create_component(settings_pe, 'Microsoft-Windows-Setup')

    disk_config = ET.SubElement(setup, 'DiskConfiguration')
    ET.SubElement(disk_config, 'WillShowUI').text = 'OnError'
    disk = ET.SubElement(disk_config, 'Disk', {'wcm:action': 'add'})
    ET.SubElement(disk, 'DiskID').text = '0'
    ET.SubElement(disk, 'WillWipeDisk').text = 'true'

    create_parts = ET.SubElement(disk, 'CreatePartitions')
    modify_parts = ET.SubElement(disk, 'ModifyPartitions')

    install_partition_id = "2"
    for idx, p in enumerate(partitions, 1):
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
        if p.get('active') == 'true':
            ET.SubElement(mp, 'Active').text = 'true'
        if p.get('typeid'):
            ET.SubElement(mp, 'TypeID').text = p['typeid']
        if not is_mbr and p.get('label') == 'Recovery':
            ET.SubElement(mp, 'GPTAttributes').text = p.get('gpt_attributes')

        if p.get('letter') == 'W':
            install_partition_id = str(idx)

    # ImageInstall
    image_install = ET.SubElement(setup, 'ImageInstall')
    os_image = ET.SubElement(image_install, 'OSImage')
    install_from = ET.SubElement(os_image, 'InstallFrom')
    metadata = ET.SubElement(install_from, 'MetaData', {'wcm:action': 'add'})
    ET.SubElement(metadata, 'Key').text = '/IMAGE/NAME'
    ET.SubElement(metadata, 'Value').text = edition_name

    install_to = ET.SubElement(os_image, 'InstallTo')
    ET.SubElement(install_to, 'DiskID').text = '0'
    ET.SubElement(install_to, 'PartitionID').text = install_partition_id

    # ProductKey
    pk = ET.SubElement(setup, 'ProductKey')
    ET.SubElement(pk, 'Key').text = product_key
    ET.SubElement(pk, 'WillShowUI').text = 'OnError'

    # specialize
    settings_spec = ET.SubElement(unattend, 'settings', {'pass': 'specialize'})
    deploy = create_component(settings_spec, 'Microsoft-Windows-Deployment')
    run_sync = ET.SubElement(deploy, 'RunSynchronous')

    commands = [
        'net.exe accounts /maxpwage:UNLIMITED',
        'reg.exe add "HKLM\\SYSTEM\\CurrentControlSet\\Control\\FileSystem" /v LongPathsEnabled /t REG_DWORD /d 1 /f',
        'reg.exe add "HKLM\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\OOBE" /v BypassNRO /t REG_DWORD /d 1 /f',
        'reg.exe add "HKLM\\SYSTEM\\CurrentControlSet\\Control\\BitLocker" /v "PreventDeviceEncryption" /t REG_DWORD /d 1 /f'
    ]

    if has_recovery:
        commands.append(r'cmd /c "reagentc /disable & reagentc /setreimage /path R:\Recovery\WindowsRE /target C:\Windows & reagentc /enable"')

    for i, cmd_text in enumerate(commands, 1):
        cmd = ET.SubElement(run_sync, 'RunSynchronousCommand', {'wcm:action': 'add'})
        ET.SubElement(cmd, 'Order').text = str(i)
        ET.SubElement(cmd, 'Path').text = cmd_text
        if "reagentc" in cmd_text:
            ET.SubElement(cmd, 'Description').text = "Configurar Windows RE"

    # oobeSystem
    settings_oobe = ET.SubElement(unattend, 'settings', {'pass': 'oobeSystem'})
    intl = create_component(settings_oobe, 'Microsoft-Windows-International-Core')
    ET.SubElement(intl, 'InputLocale').text = '0416:00010416'
    ET.SubElement(intl, 'SystemLocale').text = 'pt-BR'
    ET.SubElement(intl, 'UILanguage').text = 'pt-BR'
    ET.SubElement(intl, 'UILanguageFallback').text = 'pt-BR'
    ET.SubElement(intl, 'UserLocale').text = 'pt-BR'

    shell = create_component(settings_oobe, 'Microsoft-Windows-Shell-Setup')

    # AutoLogon
    auto = ET.SubElement(shell, 'AutoLogon')
    pwd = ET.SubElement(auto, 'Password')
    ET.SubElement(pwd, 'Value').text = password
    ET.SubElement(pwd, 'PlainText').text = 'true'
    ET.SubElement(auto, 'Enabled').text = 'true'
    ET.SubElement(auto, 'Username').text = username
    ET.SubElement(auto, 'LogonCount').text = '1'

    ET.SubElement(shell, 'ComputerName').text = computername
    ET.SubElement(shell, 'RegisteredOrganization').text = organization
    ET.SubElement(shell, 'RegisteredOwner').text = username
    ET.SubElement(shell, 'DisableAutoDaylightTimeSet').text = 'false'

    # OOBE
    oobe = ET.SubElement(shell, 'OOBE')
    ET.SubElement(oobe, 'HideEULAPage').text = 'true'
    ET.SubElement(oobe, 'HideOEMRegistrationScreen').text = 'true'
    ET.SubElement(oobe, 'HideOnlineAccountScreens').text = 'true'
    ET.SubElement(oobe, 'HideWirelessSetupInOOBE').text = 'true'
    ET.SubElement(oobe, 'NetworkLocation').text = 'Work'
    ET.SubElement(oobe, 'SkipUserOOBE').text = 'true'
    ET.SubElement(oobe, 'SkipMachineOOBE').text = 'true'
    ET.SubElement(oobe, 'ProtectYourPC').text = '3'

    # User Account
    user_accounts = ET.SubElement(shell, 'UserAccounts')
    local_accs = ET.SubElement(user_accounts, 'LocalAccounts')
    local_acc = ET.SubElement(local_accs, 'LocalAccount', {'wcm:action': 'add'})
    ET.SubElement(local_acc, 'Name').text = username
    ET.SubElement(local_acc, 'DisplayName').text = username
    ET.SubElement(local_acc, 'Group').text = 'Administrators'
    pwd_elem = ET.SubElement(local_acc, 'Password')
    ET.SubElement(pwd_elem, 'Value').text = password
    ET.SubElement(pwd_elem, 'PlainText').text = 'true'

    # Salvar arquivo
    timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    filename = f"autounattend-{timestamp}.xml"

    with open(filename, 'w', encoding='utf-8') as f:
        f.write(prettify(unattend))

    print(f"\n✅ Arquivo gerado com sucesso: {filename}")
    print(f"   Declaração XML: <?xml version=\"1.0\" encoding=\"utf-8\"?>")

if __name__ == "__main__":
    random.seed()
    main()
