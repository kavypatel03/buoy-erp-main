from PIL import Image, ImageDraw, ImageFont
import os

width, height = 1024, 1024
img = Image.new('RGBA', (width, height), (255, 255, 255, 255))

font_file = "C:\\Windows\\Fonts\\ariblk.ttf"
if not os.path.exists(font_file):
    font_file = "C:\\Windows\\Fonts\\arialbd.ttf"

# Create a temporary canvas to draw the text elements accurately centered
canvas = Image.new('RGBA', (width, height), (0, 0, 0, 0))
draw = ImageDraw.Draw(canvas)

font_b = ImageFont.truetype(font_file, 310)
font_u = ImageFont.truetype(font_file, 290)
font_o = ImageFont.truetype(font_file, 310)
font_y = ImageFont.truetype(font_file, 320)
font_excl = ImageFont.truetype(font_file, 330)

# Colors
blue = (0, 56, 255, 255)
red = (255, 51, 75, 255)
yellow = (255, 214, 0, 255)
pink = (236, 107, 186, 255)
green = (0, 176, 57, 255)

# Row 1: b u
draw.text((250, 180), "b", fill=blue, font=font_b)
draw.text((490, 195), "u", fill=red, font=font_u)

# Row 2: o y !
draw.text((215, 480), "o", fill=yellow, font=font_o)
draw.text((445, 470), "y", fill=pink, font=font_y)
draw.text((655, 450), "!", fill=green, font=font_excl)

# Calculate bounding box of the drawn text to perfectly center it in 1024x1024
bbox = canvas.getbbox()
if bbox:
    left, upper, right, lower = bbox
    text_width = right - left
    text_height = lower - upper
    
    offset_x = (width - text_width) // 2 - left
    offset_y = (height - text_height) // 2 - upper
    
    # Paste centered canvas onto main image
    img.paste(canvas, (offset_x, offset_y), canvas)
else:
    img = canvas

os.makedirs("assets/icon", exist_ok=True)
img.save("assets/icon/app_icon.png")
print("Saved 100% mathematically centered assets/icon/app_icon.png successfully")
