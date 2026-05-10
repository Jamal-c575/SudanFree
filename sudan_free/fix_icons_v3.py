import os
from PIL import Image

def resize_icon(source_path, target_path, target_size):
    try:
        img = Image.open(source_path).convert("RGBA")
        
        # Trim whitespace
        bbox = img.getbbox()
        if not bbox:
            print(f"Empty image: {source_path}")
            return
        
        cropped = img.crop(bbox)
        
        # The user wants it 5% smaller than the "maximized" version.
        # So we add a padding of 2.5% on each side.
        padding = int(target_size * 0.025)
        if padding < 1 and target_size > 20: padding = 1
        
        avail_size = target_size - 2 * padding
        
        # Resize cropped image to fit avail_size while preserving aspect ratio
        aspect = cropped.width / cropped.height
        if aspect > 1:
            new_w = avail_size
            new_h = int(new_w / aspect)
        else:
            new_h = avail_size
            new_w = int(new_h * aspect)
            
        scaled = cropped.resize((new_w, new_h), Image.Resampling.LANCZOS)
        
        # Create a new transparent image of the target size
        final_img = Image.new("RGBA", (target_size, target_size), (0,0,0,0))
        
        # Paste scaled image in the center
        offset_x = (target_size - new_w) // 2
        offset_y = (target_size - new_h) // 2
        
        # Ensure it's purely white silhouette
        r, g, b, a = scaled.split()
        white_scaled = Image.merge("RGBA", (Image.new("L", scaled.size, 255), 
                                         Image.new("L", scaled.size, 255), 
                                         Image.new("L", scaled.size, 255), 
                                         a))
                                         
        final_img.paste(white_scaled, (offset_x, offset_y))
        
        final_img.save(target_path)
        print(f"Saved {target_path} at size {target_size}x{target_size} with 5% shrink")
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
    resize_icon(source, target_path, size)

resize_icon(source, source, 96)
