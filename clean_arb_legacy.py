import json
import os

def clean_arb_legacy():
    main_arb_path = 'lib/l10n/app_pt.arb'
    
    if not os.path.exists(main_arb_path):
        print(f"Error: {main_arb_path} not found")
        return

    with open(main_arb_path, 'r', encoding='utf-8') as f:
        main_data = json.load(f)

    # Keys known to be legally moved to FoodLocalizations and NOT used by Core
    legacy_keys = [
        "loadingFood",
        "nutrientsAdvancedMacros",
        "nutrientsProteins", 
        "nutrientsCarbs", 
        "nutrientsFats", 
        "nutrientsMinerals", 
        "nutrientsSynergy", 
        "recipesQuick", 
        "recipesCulinaryIntel", 
        "recipesExpertTip", 
        "labelGlycemicImpact", 
        "labelFattyAcids", 
        "labelAminoProfile",
        "foodSafetyBio",
        "foodIdealMoment",
        "foodCriticalAlerts",
        "foodBioChem",
        "foodPreservation",
        "foodSmartSwap",
        "foodDisclaimer",
        "foodVerdict",
        "foodPros",
        "foodCons",
        "foodBiohacking",
        "foodSatietyIndex",
        "foodBodyBenefits",
        "foodAttention",
        "foodFocusEnergy",
        "foodHistoryTitle",
        "foodHistoryEmpty",
        "foodReload",
        "foodKcalPer100g",
        "foodDeleteConfirmTitle"
    ]
    
    initial_count = len(main_data)
    new_main_data = {}
    removed_count = 0
    
    for key, value in main_data.items():
        if key in legacy_keys:
            removed_count += 1
        else:
            new_main_data[key] = value

    print(f"Removed {removed_count} legacy keys. Count reduced from {initial_count} to {len(new_main_data)}.")

    with open(main_arb_path, 'w', encoding='utf-8') as f:
        json.dump(new_main_data, f, indent=2, ensure_ascii=False)

if __name__ == '__main__':
    clean_arb_legacy()
