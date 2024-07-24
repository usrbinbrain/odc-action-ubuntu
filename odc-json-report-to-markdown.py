#!/usr/bin/env python3
import json
import os
import re
import sys

def get_first_words(text, limit=250):
    words = text.split()
    current_length = 0
    result = []
    for word in words:
        # +1 accounts for the space after each word
        if current_length + len(word) + 1 > limit:
            break
        result.append(word)
        current_length += len(word) + 1
    return f"{' '.join(result)}..."

def get_report_directory(path):
    # Obter o diretório do caminho fornecido
    directory = os.path.dirname(path)
    # Adicionar barra final se não estiver presente
    if not directory.endswith('/'):
        directory += '/'
    return directory

def format_versions(text):
    text = text.replace('\n', ' ')
    text = text.replace('\r', ' ')
    pattern = r'(\b\d+\.\d+\.\d+\b)'
    formatted_text = re.sub(pattern, r'`\1`', text)
    return formatted_text

def get_severity_emoji(severity):
    if severity.lower() == 'critical':
        return '🔴'
    elif severity.lower() == 'high':
        return '🟣'
    elif severity.lower() == 'medium':
        return '🟡'
    elif severity.lower() == 'low':
        return '🔵'
    else:
        return '⚠️'

def add_reference_link_cve(cve):
    if cve.startswith('CVE-'):
        return f"[{cve}](https://nvd.nist.gov/vuln/detail/{cve})"
    elif cve.startswith('GHSA-'):
        return f"[{cve}](https://github.com/advisories/{cve})"
    elif cve.startswith('SNYK-'):
        return f"[{cve}](https://snyk.io/vuln/{cve})"
    elif cve.startswith('ntap-'):
        return f"[{cve}](https://security.netapp.com/advisory/{cve})"
    else:
        return None

def json_to_markdown(json_file, markdown_file):
    with open(json_file, 'r') as f:
        data = json.load(f)

    with open(markdown_file, 'w') as f:
        f.write(f"# Dependency-Check Report\n\n")
        f.write(f"## Project: {data.get('projectInfo', {}).get('name', 'Unknown')}\n")
        f.write(f"Generated on: {data.get('projectInfo', {}).get('reportDate', 'Unknown')}\n\n")

        dependencies = data.get('dependencies', [])
        vulnerable_dependencies = [d for d in dependencies if d.get('vulnerabilities', [])]

        if not vulnerable_dependencies:
            f.write("No vulnerabilities found.\n")
            return

        for dependency in vulnerable_dependencies:
            f.write(f"### Dependency: {dependency.get('fileName', 'Unknown')}\n\n")
            f.write(f"**File Path:** {dependency.get('filePath', 'Unknown')}\n\n")

            vulnerabilities = dependency.get('vulnerabilities', [])
            f.write("| Severity | CVE | Description |\n")
            f.write("| --- | -------- | ----------- |\n")
            for vulnerability in vulnerabilities:
                cve = vulnerability.get('name', 'Unknown')
                cve = add_reference_link_cve(cve)
                # se o cve for None, não escrever a linha
                if cve != None:
                    severity = vulnerability.get('severity', 'Unknown')
                    description = vulnerability.get('description', 'No description provided')
                    description = format_versions(description)
                    #description = get_first_words(description, 100) # controle de quantidade de caracteres na descricao
                    emoji = get_severity_emoji(severity)
                    f.write(f"| {emoji} {severity.capitalize()} | {cve} | {description} |\n")
            f.write("\n")

if __name__ == "__main__":
    # se nao for passado um arquivo json como argumento, o script vai procurar por um arquivo chamado dependency-check-report.json
    json_file = sys.argv[1] if len(sys.argv) > 1 else "./dependency-check-report.json"
    save_dir = get_report_directory(json_file)
    markdown_file = f"{save_dir}dependency-check-report.md"

    if os.path.exists(json_file):
        json_to_markdown(json_file, markdown_file)
        print(f"Markdown report generated: {markdown_file}")
    else:
        print(f"JSON report file not found: {json_file}")
        
