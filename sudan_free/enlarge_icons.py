import os
from PIL import Image

def process_icon(path):
    try:
        img = Image.open(path).convert("RGBA")
        bbox = img.getbbox()
        if not bbox:
            print(f"Empty image: {path}")
            return
        
        # Crop to the actual logo
        cropped = img.crop(bbox)
        
        # We want to fill the original canvas size (img.width, img.height)
        # leaving maybe 10% padding instead of huge padding
        target_size = min(img.width, img.height)
        pad = int(target_size * 0.05)  # 5% padding
        avail_size = target_size - 2 * pad
        
        # Scale cropped image to fit avail_size while preserving aspect ratio
        aspect = cropped.width / cropped.height
        if aspect > 1:
            new_w = avail_size
            new_h = int(new_w / aspect)
        else:
            new_h = avail_size
            new_w = int(new_h * aspect)
            
        scaled = cropped.resize((new_w, new_h), Image.Resampling.LANCZOS)
        
        # Create a new transparent image of the original size
        new_img = Image.new("RGBA", (img.width, img.height), (0,0,0,0))
        
        # Paste scaled image in the center
        offset_x = (img.width - new_w) // 2
        offset_y = (img.height - new_h) // 2
        new_img.paste(scaled, (offset_x, offset_y))
        
        new_img.save(path)
        print(f"Enlarged {path} from {cropped.size} to {scaled.size} (canvas {img.size})")
    except Exception as e:
        print(f"Error on {path}: {e}")

res_dir = "android/app/src/main/res"
for root, dirs, files in os.walk(res_dir):
    for f in files:
        if f == "ic_notification.png":
            process_icon(os.path.join(root, f))
