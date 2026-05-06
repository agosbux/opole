import os

def add_utils_import(file_path):
    with open(file_path, 'r', encoding='utf-8') as file:
        lines = file.readlines()
    
    # Verificar si ya importa utils
    has_utils_import = any('package:opole/utils/utils.dart' in line for line in lines)
    
    if not has_utils_import:
        # Buscar donde añadir (después del último import)
        insert_index = 0
        for i, line in enumerate(lines):
            if 'import ' in line:
                insert_index = i + 1
        
        # Añadir la importación
        lines.insert(insert_index, "import 'package:opole/utils/utils.dart';\n")
        
        with open(file_path, 'w', encoding='utf-8') as file:
            file.writelines(lines)
        
        return True
    
    return False

# Ejecutar en todos los archivos .dart
for root, dirs, files in os.walk('lib'):
    for file in files:
        if file.endswith('.dart'):
            file_path = os.path.join(root, file)
            if add_utils_import(file_path):
                print(f"Added utils import to: {file_path}")