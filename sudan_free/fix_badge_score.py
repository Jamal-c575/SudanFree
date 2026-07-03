import re

with open('lib/widgets/common/verification_badge.dart', 'r', encoding='utf-8') as f:
    c = f.read()

c = re.sub(r'String _scoreLabel\(double score, bool isAr\)', r'String _scoreLabel(double score, BuildContext context)', c)
c = re.sub(r'_scoreLabel\(score, isAr\)', r'_scoreLabel(score, context)', c)
c = re.sub(r'_scoreLabel\(widget\.trustScore \?\? 0\.0, isAr\)', r'_scoreLabel(widget.trustScore ?? 0.0, context)', c)
c = re.sub(r'_scoreLabel\(score, false\)', r'_scoreLabel(score, context)', c)

with open('lib/widgets/common/verification_badge.dart', 'w', encoding='utf-8') as f:
    f.write(c)
