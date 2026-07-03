import re

with open('lib/widgets/mentions/mention_overlay.dart', 'r', encoding='utf-8') as f:
    c = f.read()

c = re.sub(r'Widget _buildEmptyState\(\)', r'Widget _buildEmptyState(BuildContext context)', c)
c = re.sub(r'_buildEmptyState\(\)', r'_buildEmptyState(context)', c)

with open('lib/widgets/mentions/mention_overlay.dart', 'w', encoding='utf-8') as f:
    f.write(c)
