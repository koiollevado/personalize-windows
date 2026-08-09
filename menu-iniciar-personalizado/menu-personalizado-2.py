import os
import xml.etree.ElementTree as ET
from xml.dom import minidom

def pretty_print(elem):
    rough_string = ET.tostring(elem, 'utf-8')
    reparsed = minidom.parseString(rough_string)
    return reparsed.toprettyxml(indent="  ")

def criar_layout_xml():
    """
    Cria LayoutModification.xml unificado para Windows 10:
    - Menu Iniciar sem tiles fixos
    - Taskbar apenas com Explorer + Notepad
    """
    root = ET.Element("LayoutModificationTemplate", {
        "xmlns": "http://schemas.microsoft.com/Start/2014/LayoutModification",
        "xmlns:defaultlayout": "http://schemas.microsoft.com/Start/2014/FullDefaultLayout",
        "xmlns:start": "http://schemas.microsoft.com/Start/2014/StartLayout",
        "xmlns:taskbar": "http://schemas.microsoft.com/Start/2014/TaskbarLayout",
        "Version": "1"
    })

    # ===== MENU INICIAR (sem tiles fixos) =====
    ET.SubElement(root, "LayoutOptions", {"StartTileGroupCellWidth": "6"})

    default_override = ET.SubElement(root, "DefaultLayoutOverride")
    start_collection = ET.SubElement(default_override, "StartLayoutCollection")
    ET.SubElement(start_collection, "defaultlayout:StartLayout", {"GroupCellWidth": "6"})

    # ===== TASKBAR (somente Explorer + Notepad) =====
    taskbar_collection = ET.SubElement(root, "CustomTaskbarLayoutCollection", {
        "PinListPlacement": "Replace"
    })

    taskbar_layout = ET.SubElement(taskbar_collection, "defaultlayout:TaskbarLayout")
    pin_list = ET.SubElement(taskbar_layout, "taskbar:TaskbarPinList")

    # Explorador de Arquivos
    ET.SubElement(pin_list, "taskbar:DesktopApp", {
        "DesktopApplicationID": "Microsoft.Windows.Explorer"
    })

    # Bloco de Notas (caminho clássico do Windows 10)
    ET.SubElement(pin_list, "taskbar:DesktopApp", {
        "DesktopApplicationLinkPath": r"%APPDATA%\Microsoft\Windows\Start Menu\Programs\Accessories\Notepad.lnk"
    })

    return pretty_print(root)

def criar_estrutura_oem(base_path):
    """Cria a estrutura $OEM$\\$1\\Users\\Default\\AppData\\Local\\Microsoft\\Windows\\Shell"""
    caminho_final = os.path.join(
        base_path,
        "$OEM$",
        "$1",
        "Users",
        "Default",
        "AppData",
        "Local",
        "Microsoft",
        "Windows",
        "Shell"
    )
    os.makedirs(caminho_final, exist_ok=True)
    return caminho_final

def gerar_trecho_autounattend():
    """Gera o trecho pronto para colar no autounattend.xml"""
    trecho = r'''
<!-- ============================================================
     ADICIONE ESTE BLOCO DENTRO DO <settings pass="oobeSystem">
     (ou crie a passagem se ela ainda não existir)
     ============================================================ -->

<settings pass="oobeSystem">
  <component name="Microsoft-Windows-Shell-Setup"
             processorArchitecture="amd64"
             publicKeyToken="31bf3856ad364e35"
             language="neutral"
             versionScope="nonSxS"
             xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State"
             xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">

    <!-- Aplica o LayoutModification.xml no primeiro logon -->
    <FirstLogonCommands>
      <SynchronousCommand wcm:action="add">
        <Order>1</Order>
        <Description>Aplicar LayoutModification.xml (Menu Iniciar + Taskbar)</Description>
        <CommandLine>cmd /c copy /Y "C:\Users\Default\AppData\Local\Microsoft\Windows\Shell\LayoutModification.xml" "%LOCALAPPDATA%\Microsoft\Windows\Shell\LayoutModification.xml" &amp; taskkill /f /im explorer.exe &amp; start explorer.exe</CommandLine>
      </SynchronousCommand>
    </FirstLogonCommands>

  </component>
</settings>
'''
    return trecho.strip()

def main():
    print("=" * 70)
    print("  Configurador Unificado - Menu Iniciar + Taskbar (Windows 10)")
    print("=" * 70)
    print("\nConfiguração:")
    print("  • Menu Iniciar → Sem nenhum tile fixo (prioriza apps recentes)")
    print("  • Taskbar     → Apenas Explorador de Arquivos + Bloco de Notas\n")

    xml_str = criar_layout_xml()

    print("Escolha uma opção:")
    print("1 - Gerar apenas LayoutModification.xml (uso local)")
    print("2 - Gerar estrutura $OEM$ + copiar para mídia de instalação")
    print("3 - Gerar apenas o trecho para o autounattend.xml")
    print("4 - Fazer tudo (OEM + autounattend)")
    
    opcao = input("\nDigite a opção (1-4): ").strip()

    # -------------------------------------------------
    # Opção 1 - Apenas o arquivo local
    # -------------------------------------------------
    if opcao == "1":
        file_path = "LayoutModification.xml"
        with open(file_path, "w", encoding="utf-8") as f:
            f.write(xml_str)
        print(f"\n✅ Arquivo '{file_path}' gerado com sucesso!")

    # -------------------------------------------------
    # Opção 2 ou 4 - Estrutura $OEM$
    # -------------------------------------------------
    if opcao in ("2", "4"):
        print("\n--- Geração da estrutura $OEM$ ---")
        midia = input("Informe o caminho da pasta raiz da mídia de instalação\n"
                      "(ex: D:\\  ou  E:\\Win10Media): ").strip().rstrip("\\/")

        if not os.path.isdir(midia):
            print("❌ Caminho da mídia inválido!")
            return

        pasta_shell = criar_estrutura_oem(midia)
        destino_xml = os.path.join(pasta_shell, "LayoutModification.xml")

        with open(destino_xml, "w", encoding="utf-8") as f:
            f.write(xml_str)

        print(f"\n✅ Arquivo gerado em:")
        print(f"   {destino_xml}")
        print("\nEstrutura criada:")
        print(f"   {midia}\\$OEM$\\$1\\Users\\Default\\AppData\\Local\\Microsoft\\Windows\\Shell\\")

    # -------------------------------------------------
    # Opção 3 ou 4 - Trecho do autounattend.xml
    # -------------------------------------------------
    if opcao in ("3", "4"):
        print("\n--- Trecho para o autounattend.xml ---")
        trecho = gerar_trecho_autounattend()
        
        with open("trecho_autounattend_LayoutModification.txt", "w", encoding="utf-8") as f:
            f.write(trecho)
        
        print("\n✅ Trecho salvo em: trecho_autounattend_LayoutModification.txt")
        print("\nCole o conteúdo abaixo dentro da passagem <settings pass=\"oobeSystem\"> do seu autounattend.xml:\n")
        print("-" * 70)
        print(trecho)
        print("-" * 70)

    # -------------------------------------------------
    # Informações finais
    # -------------------------------------------------
    print("\n" + "=" * 70)
    print("RESUMO DA CONFIGURAÇÃO (Windows 10)")
    print("=" * 70)
    print("Menu Iniciar:")
    print("  • Nenhum tile fixo")
    print("  • Prioriza lista de 'Aplicativos mais usados'")
    print()
    print("Taskbar:")
    print("  • Apenas: Explorador de Arquivos + Bloco de Notas")
    print("  • Todos os outros ícones padrão são removidos")
    print()
    print("Recomendação extra (Configurações → Personalização → Iniciar):")
    print("  • Mostrar aplicativos mais usados → ATIVADO")
    print("  • Ocasionalmente mostrar sugestões → DESATIVADO")
    print("=" * 70)

if __name__ == "__main__":
    main()
