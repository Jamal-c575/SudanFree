import re

with open('lib/widgets/common/verification_badge.dart', 'r', encoding='utf-8') as f:
    c = f.read()

c = re.sub(r'String _getTooltipText\(_BadgeLevel level, bool isAr\)', r'String _getTooltipText(_BadgeLevel level, BuildContext context)', c)
c = re.sub(r'_getTooltipText\(level, isAr\)', r'_getTooltipText(level, context)', c)

with open('lib/widgets/common/verification_badge.dart', 'w', encoding='utf-8') as f:
    f.write(c)
