import re
import os

os.makedirs("functions/src", exist_ok=True)

with open("functions/index.js", "r") as f:
    content = f.read()

# Define the boundaries of exports
export_pattern = re.compile(r'^(?:/\*\*.*?\*/\n)?exports\.(\w+)\s*=\s*(.*?)(?=\n(?:/\*\*.*?\*/\n)?exports\.|$)', re.DOTALL | re.MULTILINE)

matches = export_pattern.findall(content)

preamble = content[:content.find("exports.")] if "exports." in content else content

# Fix preamble to properly initialize db if it's missing (it was missing `const db = getFirestore();`)
if "const db =" not in preamble:
    preamble = preamble.replace('const { getFirestore } = require("firebase-admin/firestore");', 
                                'const { getFirestore } = require("firebase-admin/firestore");\nconst db = getFirestore();')

if "const authAdmin =" not in preamble:
    preamble = preamble.replace('const { getAuth } = require("firebase-admin/auth");', 
                                'const { getAuth } = require("firebase-admin/auth");\nconst authAdmin = getAuth();')

if "const messaging =" not in preamble:
    preamble = preamble.replace('const { getMessaging } = require("firebase-admin/messaging");', 
                                'const { getMessaging } = require("firebase-admin/messaging");\nconst messaging = getMessaging();')

if "const isProduction =" not in preamble:
    preamble += "\nconst isProduction = process.env.IS_PRODUCTION === 'true';\n"

if "const getBucket =" not in preamble:
    preamble += "\nconst getBucket = () => require('firebase-admin/storage').getStorage().bucket();\n"

if "initializeApp" not in preamble or "initializeApp()" not in preamble:
    preamble = preamble.replace('const { initializeApp } = require("firebase-admin/app");', 
                                'const { initializeApp } = require("firebase-admin/app");\ninitializeApp();')

# Extract top level variables and functions for module.exports
vars_funcs = re.findall(r'^(?:async )?function (\w+)\(', preamble, re.MULTILINE)
vars_consts = re.findall(r'^const (\w+)\s*=', preamble, re.MULTILINE)
vars_lets = re.findall(r'^let (\w+)\s*=', preamble, re.MULTILINE)

exports_list = set(vars_funcs + vars_consts + vars_lets)
# Remove requires
exports_list = {x for x in exports_list if x not in ['onDocumentCreated', 'onDocumentUpdated', 'onCall', 'HttpsError', 'onSchedule', 'FieldValue', 'initializeApp', 'getFirestore', 'getAuth', 'getStorage', 'getMessaging']}

with open("functions/src/utils.js", "w") as f:
    f.write(preamble)
    f.write("\nmodule.exports = {\n")
    for x in exports_list:
        f.write(f"    {x},\n")
    f.write("};\n")

groups = {
    "notifications": ["onNotificationCreated", "onReviewCreated", "onMessageCreated", "adminSendNotification", "notifyNewLocalProviders"],
    "users": ["sendWhatsAppOTP", "verifyWhatsAppOTP", "deleteUserAccount", "onUserUpdated", "onVerificationRequestUpdated"],
    "jobs": ["onJobUpdated"],
    "ads": ["onAdCreated"],
    "media": ["generateCloudinarySignature"]
}

for module_name, func_names in groups.items():
    with open(f"functions/src/{module_name}.js", "w") as f:
        f.write("const utils = require('./utils');\n")
        f.write("const { onDocumentCreated, onDocumentUpdated } = require('firebase-functions/v2/firestore');\n")
        f.write("const { onCall, HttpsError } = require('firebase-functions/v2/https');\n")
        f.write("const { onSchedule } = require('firebase-functions/v2/scheduler');\n")
        f.write("const { FieldValue } = require('firebase-admin/firestore');\n\n")
        
        # Destructure all utils so functions work as before
        if len(exports_list) > 0:
            f.write(f"const {{ {', '.join(exports_list)} }} = utils;\n\n")
            
        for name, body in matches:
            if name in func_names:
                # Need to find the doc comment from original
                idx = content.find(f"exports.{name}")
                start_idx = content.rfind("/**", 0, idx)
                if start_idx != -1 and "*/" in content[start_idx:idx]:
                    doc_comment = content[start_idx:content.find("*/", start_idx)+2]
                    f.write(doc_comment + "\n")
                
                f.write(f"exports.{name} = {body}\n\n")

# Write new index.js
with open("functions/index.js", "w") as f:
    f.write("require('./src/utils'); // Initialize Firebase\n\n")
    for module_name in groups.keys():
        f.write(f"Object.assign(exports, require('./src/{module_name}'));\n")

print(f"Successfully split {len(matches)} exports.")
