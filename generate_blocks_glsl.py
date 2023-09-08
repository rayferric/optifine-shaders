import os

# Open /shaders/block.properties
with open(
    os.path.join(os.path.dirname(__file__), "shaders", "block.properties"), "r"
) as f:
    lines = f.readlines()

# For each line in form "block.<id>=..." read the comment above it "# Block category name".
# If such line with a comment is found, remember the category name and the numeric id in a dictionary.
category_ids = {}
for i, line in enumerate(lines):
    if line.startswith("block."):
        block_id = line.split("=")[0].split(".")[1]
        if lines[i - 1].startswith("#"):
            block_category = lines[i - 1].split("# ")[1].strip()
            category_ids[block_category] = block_id

# Convert all block categories to UPPERCASE_SNAKE_CASE
category_ids = {k.upper().replace(" ", "_"): v for k, v in category_ids.items()}

# Generate /shaders/src/modules/blocks.glsl
generated = []
generated.append("#ifndef BLOCKS_GLSL")
generated.append("#define BLOCKS_GLSL")
generated.append("")
generated.append('// This file is generated from block.properties using generate_blocks_glsl.py;')
generated.append("// Please do not edit.")
generated.append("")
generated.append("#define BLOCKS_UNKNOWN 0")

for block_category, block_id in category_ids.items():
    generated.append(f"#define BLOCKS_{block_category} {block_id}")

generated.append("")
generated.append("#endif // BLOCKS_GLSL")
generated.append("")

# Write to /shaders/src/modules/blocks.glsl
with open(
    os.path.join(os.path.dirname(__file__), "shaders", "src", "modules", "blocks.glsl"),
    "w",
) as f:
    f.write("\n".join(generated))
