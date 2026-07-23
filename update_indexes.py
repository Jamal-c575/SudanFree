import json
with open('firestore.indexes.json', 'r') as f:
    data = json.load(f)

# Add indexes for ai_search_tools.dart
indexes_to_add = [
    {
      "collectionGroup": "users",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "role", "order": "ASCENDING" },
        { "fieldPath": "searchKeywords", "arrayConfig": "CONTAINS" }
      ]
    },
    {
      "collectionGroup": "users",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "role", "order": "ASCENDING" },
        { "fieldPath": "rating", "order": "DESCENDING" }
      ]
    }
]

for idx in indexes_to_add:
    if idx not in data['indexes']:
        data['indexes'].append(idx)

with open('firestore.indexes.json', 'w') as f:
    json.dump(data, f, indent=2)

print("Updated firestore.indexes.json")
