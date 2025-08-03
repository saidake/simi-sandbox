import sys
import re

def extract_script_doc(script_path):
    with open(script_path, encoding='utf-8') as f:
        lines = f.readlines()

    start = "# ************************************************************************************\n"
    end = "# Author: Craig Brown\n"

    try:
        start_index = lines.index(start) + 1
        end_index = lines.index(end)
    except ValueError:
        raise RuntimeError("Failed to find script doc markers in script file.")

    extracted = []
    for line in lines[start_index:end_index]:
        # Match only lines starting with '#' followed by a space or nothing
        if re.match(r"^#\s?$", line):
            extracted.append('\n')  # Preserve as a real empty line
        else:
            extracted.append(re.sub(r"^#\s?", "", line))

    return extracted

def replace_in_readme(readme_path, new_lines, script_name):
    with open(readme_path, encoding='utf-8') as f:
        lines = f.readlines()

    start_pattern = f"![](./docs/assets/scripts/{script_name}.svg)\n"
    start_index = None
    end_index = None

    for i, line in enumerate(lines):
        if start_index is None and line == start_pattern:
            start_index = i + 1
        elif start_index is not None and re.match(r"^#{1,6} ", line):
            end_index = i
            break

    if start_index is None:
        raise RuntimeError("Could not find the start replacement string in README.")
    if  end_index is None:
        raise RuntimeError("Could not find the end replacement string in README.")

    updated = lines[:start_index] + new_lines + lines[end_index:]
    with open(readme_path, 'w', encoding='utf-8') as f:
        f.writelines(updated)

if __name__ == "__main__":
    script_name = 'cpfiles'

    script_path = rf'C:\Users\saidake\Desktop\DevProjects\simi-sandbox\scripts\{script_name}.sh'
    readme_path = r'C:\Users\saidake\Desktop\DevProjects\simi-sandbox\README.md'

    doc_lines = extract_script_doc(script_path)
    replace_in_readme(readme_path, doc_lines, script_name)
    print("README updated successfully.")
