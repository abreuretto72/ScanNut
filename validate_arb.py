import json
import sys

files = [
    r'e:\antigravity_projetos\ScanNut\lib\l10n\app_en.arb',
    r'e:\antigravity_projetos\ScanNut\lib\l10n\app_es.arb',
    r'e:\antigravity_projetos\ScanNut\lib\l10n\app_pt.arb',
    r'e:\antigravity_projetos\ScanNut\lib\l10n\app_pt_PT.arb'
]

for f in files:
    try:
        with open(f, 'r', encoding='utf-8') as file:
            json.load(file)
            print(f"✅ {f} is VALID")
    except Exception as e:
        print(f"❌ {f} is INVALID: {e}")
