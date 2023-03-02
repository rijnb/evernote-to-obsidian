#!/usr/bin/env zsh
#
# This file uses YARLE to convert an Evernote .enex file
# to an Obsidian readable Markdown file system.

# ----------------
# Check input parameters
# ----------------

echo "Evernote to Obsidian converter."
if [ $# -ne 2 ]
then
    echo "Usage: $(basename $0) output-dir input-file.enex"
    exit -1
fi
OUTPUT="$1"
INPUT="$2"
CONFIG=$(dirname "$0")/evernote_config.json
TEMPLATE=$(dirname "$0")/evernote_converted_note.template

if [ ! -d "$OUTPUT" ]
then
    echo "ERROR: The output direcctory $OUTPUT does not exist."
    echo "       Please check if it's correct, or create it first."
    exit -1
fi

if [ ! -f "$INPUT" ]
then
    echo "ERROR: The input file $FILE cannot be found."
    exit -1
fi

INPUT_FILENAME=$(basename "$INPUT")
INPUT_FILENAME_EXT="${INPUT_FILENAME##*.}"
if [ "$INPUT_FILENAME_EXT" != "enex" ]
then
    echo "ERROR: The input file $INPUT_FILENAME must end with .enex (not .$INPUT_FILENAME_EXT)."
    exit -1
fi

if [ ! -f "$CONFIG" ]
then
    echo "ERROR: The configuration file $CONFIG cannot be found."
    exit -1
fi

if [ ! -f "$TEMPLATE" ]
then
    echo "ERROR: The note template file $TEMPLATE cannot be found."
    exit -1
fi

# ----------------
# Create input files (config and note template)
# ----------------

TODAY=$(date +%Y-%m-%d)
TEMPLATE_PATCHED="$TEMPLATE.patched"
cat "$TEMPLATE" |
    sed -e "s:@IMPORT:$TODAY:g" > "$TEMPLATE_PATCHED"
cat "$CONFIG.template" |
    sed -e "s:@INPUT:\"$INPUT\":g" |
    sed -e "s:@OUTPUT:\"$OUTPUT\":g" |
    sed -e "s:@TEMPLATE:\"$TEMPLATE_PATCHED\":g" > "$CONFIG"

# ----------------
# Run Yarle
# ----------------

echo "Output directory     : $OUTPUT"
echo "Input file (Evernote): $INPUT_FILENAME ("$(dirname "$INPUT")")"
npx -p yarle-evernote-to-md@latest yarle --configFile "$CONFIG"
if [ $? -ne 0 ]
then
    error "WARNING: an error may have occurred while converting"
    error "         $INPUT to directory $OUTPUT"
    exit 1
fi

# ----------------
# Run post-conversion scripts
# ----------------

MD_DIR="$OUTPUT/notes/"$(basename "$INPUT" .enex)
echo "Run post-conversion scripts in $MD_DIR..."
if [ ! -d ]
then
    echo "ERROR: Missing output directory $MD_DIR"
    exit 1
fi
cd "$MD_DIR"

for FILE in *.md
do 
    # Embed <<...>> links in backticks.
    sed -i .bak 's/<<\([^>]*\)>>/`<<\1>>`/g' "$FILE"

    # Remove whitespace before tables.
    sed -i .bak 's/^[	 ]*|\(.*\)|[	 ]*$/|\1|/' "$FILE"

    rm "$FILE".bak
done
echo "Done"
