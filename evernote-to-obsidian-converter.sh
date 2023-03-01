# This file uses YARLE to convert an Evernote .enex file
# to an Obsidian readable Markdown file system.

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

INPUT_FILENAME=$(basename -- "$INPUT")
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

TODAY=$(date +%Y-%m-%d)
TEMPLATE_PATCHED="$TEMPLATE.patched"
cat "$TEMPLATE" |
    sed -e "s:@IMPORT:$TODAY:g" > "$TEMPLATE_PATCHED"
cat "$CONFIG.template" |
    sed -e "s:@INPUT:\"$INPUT\":g" |
    sed -e "s:@OUTPUT:\"$OUTPUT\":g" |
    sed -e "s:@TEMPLATE:\"$TEMPLATE_PATCHED\":g" > "$CONFIG"

echo "Output directory     : $OUTPUT"
echo "Input file (Evernote): $INPUT_FILENAME ("$(dirname "$INPUT")")"
npx -p yarle-evernote-to-md@latest yarle --configFile "$CONFIG"
if [ $? -ne 0 ]
then
    error "WARNING: an error may have occurred while converting"
    error "         $INPUT to directory $OUTPUT"
    exit 1
fi
