from PIL import Image, ImageDraw, ImageFont, ImageFilter, ImageChops, ImageEnhance

def run():
    process('rocky.png', '../Survival2D/assets/images/rocky.png')

def process(dir_in, dir_out):
    img = Image.open(dir_in).convert('RGBA').resize((64, 64))
    out = Image.new('RGBA', (512, 384), color=0)
    h = make_tile_h(img)
    v = make_tile_v(img)
    image_mapping = {}
    image_mapping["midleft"] = apply_gradient(v, 'L')
    image_mapping["midright"] = apply_gradient(v, 'R')
    image_mapping["midtop"] = apply_gradient(v, 'U')
    image_mapping["midbottom"] = apply_gradient(h, 'D')
    image_mapping["topleft"] = apply_gradient(image_mapping["midtop"], 'L')
    image_mapping["topright"] = apply_gradient(image_mapping["midtop"], 'R')
    image_mapping["bottomleft"] = apply_gradient(image_mapping["midbottom"], 'L')
    image_mapping["bottomright"] = apply_gradient(image_mapping["midbottom"], 'R')
    image_mapping["h"] = apply_gradient(image_mapping["midbottom"], 'U')
    image_mapping["v"] = apply_gradient(image_mapping["midleft"], 'R')
    image_mapping["left"] = apply_gradient(image_mapping["h"], 'L')
    image_mapping["right"] = apply_gradient(image_mapping["h"], 'R')
    image_mapping["top"] = apply_gradient(image_mapping["v"], 'U')
    image_mapping["bottom"] = apply_gradient(image_mapping["bottomleft"], 'R')
    image_mapping["single"] = apply_gradient(image_mapping["top"], 'D')
    image_mapping["all"] = v
    coord_mapping = (
        ("single", "left", "h", "right", "top", "topleft", "midtop", "topright"),
        ("topleft", "topright", "midleft", "midtop", "v", "midleft", "all", "midright"),
        ("bottomleft", "bottomright", "midbottom", "midright", "bottom", "bottomleft", "midbottom", "bottomright"),
        ("midleft", "midright", "midtop", "midtop", "all", "all", "all", "all"),
        ("midleft", "midright", "midbottom", "midbottom", "all", "all", "all", "all"),
        ("all", "all", "all", "all", "all", "all", "all", "all"),
    )

    y = 0
    for subimg_row in coord_mapping:
        x = 0
        for subimg in subimg_row:
            out.paste(image_mapping[subimg], (x, y))
            x += 64
        y += 64

    out = out.convert('RGB')
    out = out.filter(ImageFilter.SHARPEN)
    out.show()
    out.save(dir_out, 'PNG')


def make_tile_v(img):
    out = img
    half = img.resize((64, 32))
    out.paste(half, (0, 0))
    out.paste(half, (0, 32))
    enh = ImageEnhance.Brightness(out)
    out = enh.enhance(.8).transpose(Image.FLIP_LEFT_RIGHT)
    enh = ImageEnhance.Contrast(out)
    out = enh.enhance(.8)
    return out

def make_tile_h(img):
    out = img.resize((64, 64))
    upper = make_tile_v(out).crop((0, 0, 64, 32))
    lower = img.crop((2,8,62,56)).resize((64, 32))

    out.paste(upper, (0, 0))
    out.paste(lower, (0, 32))
    return out

def make_tileable(img):
    img = img.resize((66, 66))
    return img.crop((1, 1, 65, 65))

def apply_gradient(img, side):
    if side == 'L':
        vertical = False
        flip = False
    elif side == 'R':
        vertical = False
        flip = True
    elif side == 'U':
        vertical = True
        flip = False
    elif side == 'D':
        vertical = True
        flip = True
    if vertical:
        gradient = Image.new('L', (1, 64), color=0)
        for y in range(8):
            if y == 0:
                gradient.putpixel((0, y), 100)
            elif y == 1:
                gradient.putpixel((0, y), 70)
            else:
                gradient.putpixel((0, y), 64-y*8)
        if flip:
            gradient = gradient.transpose(Image.FLIP_TOP_BOTTOM)
    else:
        gradient = Image.new('L', (64, 1), color=0)
        for x in range(8):
            if x == 0:
                gradient.putpixel((x, 0), 100)
            elif x == 1:
                gradient.putpixel((x, 0), 70)
            else:
                gradient.putpixel((x, 0), 64-x*8)
        if flip:
            gradient = gradient.transpose(Image.FLIP_LEFT_RIGHT)

    alpha = gradient.resize((64, 64))
    black_im = Image.new('RGBA', (64, 64), color=0) # i.e. black
    black_im.putalpha(alpha)
    gradient_im = Image.alpha_composite(img, black_im)
    return gradient_im

run()
