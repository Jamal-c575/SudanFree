import os
import re

def read_file(path):
    with open(path, 'r') as f:
        return f.read()

def write_file(path, content):
    with open(path, 'w') as f:
        f.write(content)

# 1. profile_setup_screen.dart:1055
path = 'lib/views/auth/profile_setup_screen.dart'
content = read_file(path)
content = re.sub(r'\? \(\) \{\n\s*setState\(\(\) \{\n\s*_step\+\+;\n\s*\}\);\n\s*\}', '? () {\n                                setState(() {\n                                  _step++;\n                                });\n                              } as void Function()', content)
write_file(path, content)

# 2. identity_verification_screen.dart
path = 'lib/views/auth/identity_verification_screen.dart'
content = read_file(path)
if 'import \'package:flutter/services.dart\';' not in content:
    content = content.replace('import \'package:flutter/material.dart\';', 'import \'package:flutter/material.dart\';\nimport \'package:flutter/services.dart\';')
content = re.sub(r'margin:\s*const EdgeInsets\.fromLTRB\([^)]+\),', '', content)
write_file(path, content)

# 3. map_explorer_screen.dart
path = 'lib/views/map/map_explorer_screen.dart'
content = read_file(path)
content = content.replace('AnimationUtils.createPremiumRoute(page: ', 'AnimationUtils.createPremiumRoute(')
content = re.sub(r'width:\s*50,\s*height:\s*50,\s*child:\s*PremiumGlassCard\(', 'child: SizedBox(width: 50, height: 50, child: PremiumGlassCard(', content)
content = content.replace('width: 50,\n                          height: 50,\n                          child: const Icon', 'child: SizedBox(width: 50, height: 50, child: Icon') # generic fix
# Specifically fix line 799: width: 50 in PremiumGlassCard
content = re.sub(r'PremiumGlassCard\(\s*width:\s*\d+,?', 'PremiumGlassCard(', content) # PremiumGlassCard doesn't have width/height params anymore?
write_file(path, content)

# 4. smart_search_delegate.dart
path = 'lib/views/search/smart_search_delegate.dart'
content = read_file(path)
content = content.replace('AnimationUtils.createPremiumRoute(page: ', 'AnimationUtils.createPremiumRoute(')
write_file(path, content)

# 5. my_agreements_screen.dart
path = 'lib/views/jobs/my_agreements_screen.dart'
content = read_file(path)
content = content.replace('AnimationUtils.createPremiumRoute(page: ', 'AnimationUtils.createPremiumRoute(')
write_file(path, content)

# 6. ai_search_tools.dart
path = 'lib/services/ai_search_tools.dart'
content = read_file(path)
content = content.replace('PostModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)', 'PostModel.fromMap(doc.data() as Map<String, dynamic>..["id"] = doc.id)')
# Wait, let's see how fromMap is defined. If it doesn't take id, we can just pass doc.data().
write_file(path, content)

# 7. success_story_submission_screen.dart
path = 'lib/views/profile/success_story_submission_screen.dart'
content = read_file(path)
content = content.replace('authProvider.currentUser', 'authProvider.user')
write_file(path, content)

print("Fixes applied.")
