import os
from PIL import Image

def resize_icon(source_path, target_path, target_size):
    try:
        img = Image.open(source_path).convert("RGBA")
        bbox = img.getbbox()
        if not bbox:
            print(f"Empty image: {source_path}")
            return
            
        cropped = img.crop(bbox)
        
        # We want to fill the target size, with 1px padding to be safe
        pad = 0
        if target_size > 36:
            pad = 2
        elif target_size > 24:
            pad = 1
            
        avail_size = target_size - 2 * pad
        
        aspect = cropped.width / cropped.height
        if aspect > 1:
            new_w = avail_size
            new_h = int(new_w / aspect)
        else:
            new_h = avail_size
            new_w = int(new_h * aspect)
            
        scaled = cropped.resize((new_w, new_h), Image.Resampling.LANCZOS)
        
        new_img = Image.new("RGBA", (target_size, target_size), (0,0,0,0))
        
        offset_x = (target_size - new_w) // 2
        offset_y = (target_size - new_h) // 2
        new_img.paste(scaled, (offset_x, offset_y))
        
        new_img.save(target_path)
        print(f"Saved {target_path} at size {target_size}x{target_size}")
    except Exception as e:
        print(f"Error on {source_path}: {e}")

source = "android/app/src/main/res/drawable/ic_notification.png"
sizes = {
    "drawable-mdpi": 24,
    "drawable-hdpi": 36,
    "drawable-xhdpi": 48,
    "drawable-xxhdpi": 72,
    "drawable-xxxhdpi": 96,
}

for folder, size in sizes.items():
    target_path = os.path.join("android/app/src/main/res", folder, "ic_notification.png")
    if os.path.exists(target_path):
        resize_icon(source, target_path, size)

# Also fix the base drawable just in case
resize_icon(source, source, 96)
