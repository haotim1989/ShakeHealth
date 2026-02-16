import json
import os

# Define file paths
SAMPLE_DATA_PATH = "/Users/tienminhao/Desktop/Google Antigravity/Test_20260129_Drink/ShakeHealth/Sources/Resources/SampleData.json"
OUTPUT_PATH = SAMPLE_DATA_PATH # Overwrite directly

def patch_caffeine_data():
    if not os.path.exists(SAMPLE_DATA_PATH):
        print(f"Error: File not found at {SAMPLE_DATA_PATH}")
        return

    try:
        with open(SAMPLE_DATA_PATH, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        updated_count = 0
        affected_brands = set()

        if "drinks" in data:
            for drink in data["drinks"]:
                # Check directly for caffeine_content == -1
                if drink.get("caffeine_content") == -1:
                    # Update has_caffeine to None (null in JSON)
                    if drink.get("has_caffeine") is not None:
                        drink["has_caffeine"] = None
                        updated_count += 1
                        affected_brands.add(drink.get("brand_id"))

        # Save changes
        with open(OUTPUT_PATH, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
        
        print(f"Successfully updated {updated_count} drinks.")
        print(f"Affected brands ({len(affected_brands)}): {', '.join(sorted(list(affected_brands)))}")

    except Exception as e:
        print(f"An error occurred: {e}")

if __name__ == "__main__":
    patch_caffeine_data()
