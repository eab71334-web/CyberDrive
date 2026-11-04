from PIL import Image, ImageDraw
S = 1024
img = Image.new("RGB", (S, S), (11, 18, 32))
d = ImageDraw.Draw(img)
for i in range(14):
    r = 430 - i * 6
    c = (0, 200 - i * 8, 255 - i * 8)
    d.ellipse((S/2 - r, S/2 - r, S/2 + r, S/2 + r), outline=c, width=4)
body = [(170, 600), (330, 440), (760, 400), (860, 470), (860, 600)]
d.polygon(body, fill=(190, 198, 208))
d.polygon([(330, 440), (560, 405), (560, 500), (270, 520)], fill=(25, 35, 55))
d.polygon([(560, 405), (760, 400), (790, 470), (560, 500)], fill=(35, 48, 72))
d.line([(170, 600), (330, 440), (760, 400), (860, 470), (860, 600), (170, 600)], fill=(255, 255, 255), width=6)
for cx in (330, 700):
    d.ellipse((cx - 85, 540, cx + 85, 710), fill=(15, 15, 20))
    d.ellipse((cx - 45, 580, cx + 45, 670), fill=(0, 210, 255))
    d.ellipse((cx - 18, 607, cx + 18, 643), fill=(15, 15, 20))
bx, by = 512, 840
pts = [(bx - 40, by - 45), (bx + 40, by + 35), (bx, by + 75), (bx, by - 75), (bx + 40, by - 35), (bx - 40, by + 45)]
d.line(pts, fill=(0, 210, 255), width=14, joint="curve")
img.save("assets/icon.png")
