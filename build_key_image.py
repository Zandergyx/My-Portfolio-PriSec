"""Build Key.jpg with EXIF hint and a zip-embedded .vault_flag for binwalk."""
import io
import zipfile
from pathlib import Path

from PIL import Image
import piexif

VAULT_TEXT = """# Zander's Portfolio Vault
# Copy the line below into the flag box on the main portfolio (Cybersecurity section).

CTF{zander_goh_vault_unlock}
"""

METADATA_HINT = "check for hidden files"

img = Image.new("RGB", (640, 400), (7, 60, 115))
pixels = img.load()
for y in range(400):
    for x in range(640):
        band = ((x // 48) + (y // 48)) % 2
        pixels[x, y] = (0, 123, 255) if band else (0, 198, 255)

exif_dict = {
    "0th": {piexif.ImageIFD.ImageDescription: METADATA_HINT.encode("utf-8")},
    "Exif": {
        piexif.ExifIFD.UserComment: piexif.helper.UserComment.dump(
            METADATA_HINT, encoding="unicode"
        )
    },
}
exif_bytes = piexif.dump(exif_dict)

jpeg_buffer = io.BytesIO()
img.save(jpeg_buffer, format="JPEG", quality=90, exif=exif_bytes)
jpeg_data = jpeg_buffer.getvalue()

zip_buffer = io.BytesIO()
with zipfile.ZipFile(zip_buffer, "w", zipfile.ZIP_DEFLATED) as archive:
    archive.writestr(".vault_flag", VAULT_TEXT)
zip_data = zip_buffer.getvalue()

out_path = Path(__file__).resolve().parent / "Key.jpg"
out_path.write_bytes(jpeg_data + zip_data)
print(f"Wrote {out_path} ({len(jpeg_data)} byte JPEG + {len(zip_data)} byte zip payload)")
