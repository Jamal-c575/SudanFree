import os
from PIL import Image

res_dir = "android/app/src/main/res"
for root, dirs, files in os.walk(res_dir):
    for f in files:
        if f == "ic_notification.png":
            path = os.path.join(root, f)
            print(f"{path}: {Image.open(path).size}")
