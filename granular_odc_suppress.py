import re
import sys
import json
import os

config_suppress = 'granular_odc_suppress.json'
odc_suppress = 'suppression.xml'

def find_repo(repo_name, repo_list):
    return [item for item in repo_list if item['repo_name'] == repo_name] or []

def add_cves_to_xml_as_string(cve_list, xml_file):
    # Ler o conteúdo do arquivo como string
    with open(xml_file, 'r', encoding='utf-8') as file:
        content = file.read()

    # Regex para encontrar o fechamento da última tag <suppress> antes de </suppressions>
    pattern = r'(\s*</suppress>\s*)(?=\s*</suppressions>)'
    
    # Construir o novo bloco de CVEs
    new_suppress_block = "   <suppress>\n"
    for cve in cve_list:
        new_suppress_block += f"      <cve>{cve}</cve>\n"
    new_suppress_block += "   </suppress>\n"

    # Inserir o novo bloco de CVEs antes da tag de fechamento </suppressions>
    updated_content = re.sub(pattern, r'\1' + new_suppress_block, content, flags=re.MULTILINE)

    # Escrever o conteúdo modificado de volta ao arquivo
    with open(xml_file, 'w', encoding='utf-8') as file:
        file.write(updated_content)

if __name__ == "__main__":
    # Verifica se foi passado um argumento, se não, usa o valor "default"
    repo_name = sys.argv[1] if len(sys.argv) > 1 else "default"
    # Verifica se o arquivo granular_odc_suppress.json existe
    #if os.path.exists("granular_odc_suppress.json") and repo_name != "default":
    if os.path.exists(config_suppress) and os.path.exists(odc_suppress):
        # Abre o arquivo granular_odc_suppress.json
        data = json.load(open(config_suppress))

        if repo_name != "default":
            # Procura o repositório no arquivo granular_odc_suppress.json
            repo_suppress = find_repo(repo_name, data)
            
            if repo_suppress != []:
                # Adiciona as CVEs ao arquivo suppression.xml
                repo_suppress = repo_suppress[0]['suppression']
                # coloca todos os itens da lista em uppercase
                repo_suppress = [x.upper() for x in repo_suppress]
                print(repo_suppress)
                add_cves_to_xml_as_string(repo_suppress, odc_suppress)

