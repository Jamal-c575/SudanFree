import os
from PIL import Image, ImageOps

def resize_icon(source_path, target_path, target_size):
    try:
        img = Image.open(source_path).convert("RGBA")
        
        # Trim whitespace
        bbox = img.getbbox()
        if not bbox:
            print(f"Empty image: {source_path}")
            return
        
        cropped = img.crop(bbox)
        
        # Resize to exactly target_size, NO padding
        # This will make it fill the status bar slot completely
        new_img = cropped.resize((target_size, target_size), Image.Resampling.LANCZOS)
        
        # Ensure it's purely white (silhouette) as required by Android for notification icons
        # Keep alpha, make RGB = 255,255,255
        r, g, b, a = new_img.split()
        white_img = Image.merge("RGBA", (Image.new("L", new_img.size, 255), 
                                         Image.new("L", new_img.size, 255), 
                                         Image.new("L", new_img.size, 255), 
                                         a))
        
        white_img.save(target_path)
        print(f"Saved {target_path} at size {target_size}x{target_size} (Maximized)")
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

# If the icon was 1024 before, the first run might have already shrunk it to 96.
# I should find the largest one as source if possible.
# Actually, I'll just use the one in drawable/ as it was 96 now.

for folder, size in sizes.items():
    target_path = os.path.join("android/app/src/main/res", folder, "ic_notification.png")
    resize_icon(source, target_path, size)

resize_icon(source, source, 96)
