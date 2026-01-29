import json
import os

def clean_arb():
    food_arb_path = 'lib/features/food/l10n/food_pt.arb'
    main_arb_path = 'lib/l10n/app_pt.arb'

    if not os.path.exists(food_arb_path):
        print(f"Error: {food_arb_path} not found")
        return
    
    if not os.path.exists(main_arb_path):
        print(f"Error: {main_arb_path} not found")
        return

    with open(food_arb_path, 'r', encoding='utf-8') as f:
        food_data = json.load(f)
    
    with open(main_arb_path, 'r', encoding='utf-8') as f:
        main_data = json.load(f)

    keys_to_remove = set(food_data.keys())
    # Don't remove metadata keys (starting with @) unless the base key is also removed?
    # Usually metadata keys follow the same name with @ prefix.
    
    # We also need to remove keys that are in food_pt.arb from main_data
    # including their metadata keys if they exist in main_data.
    
    initial_count = len(main_data)
    
    new_main_data = {}
    removed_count = 0
    
    for key, value in main_data.items():
        # Check if it's a metadata key
        base_key = key[1:] if key.startswith('@') else key
        
        if base_key in keys_to_remove:
            removed_count += 1
            # print(f"Removing {key}")
        else:
            new_main_data[key] = value

    print(f"Removed {removed_count} keys. Count reduced from {initial_count} to {len(new_main_data)}.")

    with open(main_arb_path, 'w', encoding='utf-8') as f:
        json.dump(new_main_data, f, indent=2, ensure_ascii=False)

if __name__ == '__main__':
    clean_arb()
