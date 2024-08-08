#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import json
import time
import sys
import os

def get_report_directory(path):
    directory = os.path.dirname(path)
    if not directory.endswith('/'):
        directory += '/'
    return directory

def now_utc():
    hora_atual_utc = time.gmtime()
    hora_formatada = time.strftime("%Y-%m-%d %H:%M:%S", hora_atual_utc)
    return f"[{hora_formatada}]"

def find_lib(odc_json_file, target_libs):
    with open(odc_json_file, 'r') as f:
        data = json.load(f)
    print(f"{now_utc()} Identificando Libs do projeto: {data.get('projectInfo', {}).get('name', 'Unknown')} ({data.get('projectInfo', {}).get('reportDate', 'Unknown')})")
    dependencies = data.get('dependencies', [])
    current_dependencies = [
        {"pkg": d['packages'][0]['id'], "path": d['filePath']}
        for d in dependencies
        if 'packages' in d and d['packages'] and 'id' in d['packages'][0] and any(d['packages'][0]['id'].endswith(lib) for lib in target_libs)
    ]
    return current_dependencies

if __name__ == "__main__":
    # Nome do arquivo JSON gerado pelo Dependency-Check
    odc_json_file = sys.argv[1]
    # le o arquivo json github_target_libs.json e carrega em target_libs
    target_libs = json.load(open(sys.argv[2]))
    # Obter o diretório do relatório
    report_path = get_report_directory(odc_json_file)
    # Nome do arquivo de relatório
    libscan_report = f"{report_path}libscan-report.md"
    # Encontrar a dependência no arquivo JSON
    search_result = find_lib(odc_json_file, target_libs)
    # Cria o arquivo de relatório
    with open(libscan_report, 'w') as f:
        f.write(f"---\n\n")
        f.write(f"### LibScan Report Libraries Found: {len(search_result)}\n\n")
        if search_result != []:
            f.write("| Library | FilePath |\n")
            f.write("| ---- | -------- |\n")
            for pkg in search_result:
                # Gera o conteúdo do relatório em formato de tabela
                f.write(f"| {pkg['pkg']} | {pkg['path']} |\n")
            f.write("\n")
        else:
            f.write(f"---\n")
    # Imprime o caminho do arquivo de relatório
    print(f"{now_utc()} LibScan Report: {libscan_report}")
    
