import csv
from collections import Counter

# Count occurrences of each category
category_counts = Counter()

with open('easy-vocabulary.csv', 'r', encoding='utf-8') as f:
    reader = csv.DictReader(f)
    for row in reader:
        cat = row['category'].strip()
        if cat:
            # Split by semicolon and process each category
            categories = [c.strip() for c in cat.split(';') if c.strip()]
            for category in categories:
                category_counts[category] += 1

# Sort by category name alphabetically
sorted_categories = sorted(category_counts.items())

# Write to categories.csv with category and count columns
with open('categories.csv', 'w', encoding='utf-8', newline='') as out:
    writer = csv.writer(out)
    writer.writerow(['category', 'count'])
    for category, count in sorted_categories:
        writer.writerow([category, count])

print(f'Extracted {len(sorted_categories)} unique categories with counts')
print(f'Total word entries: {sum(category_counts.values())}')
