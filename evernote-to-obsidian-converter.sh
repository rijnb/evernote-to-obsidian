#!/usr/bin/env zsh
#
# This file uses YARLE to convert an Evernote .enex file
# to an Obsidian readable Markdown file system.

# ----------------
# Check input parameters
# ----------------

echo "Evernote to Obsidian converter."
if [ $# -lt 2 -o $# -gt 3 ]
then
    echo "Usage: $(basename $0) output-dir input-file.enex [tags-hierarchy-file]"
    echo ""
    echo "  The tags hierarchy file is optional. If provided, it should contain per"
    echo "  line a category/tag pair. Any tag found in the markdown metadata not"
    echo "  prefixed by the corresponding category, will be prefixed it."
    echo "  Note that the metadata must be located in the first 50 lines of the file."
    echo ""
    echo "  Example:"
    echo "       mytags.txt   == companies/apple"
    echo "       mynote.md    == ---\\ntags: apple ..."
    echo "     This replace the tags line in mynote.md to:"
    echo "       mynote.md    == ---\\ntags: companies/apple ..."
    exit -1
fi
OUTPUT="$1"
INPUT="$2"
TAGS_HIERARCHY=
if [ $# -eq 3 ]
then
    TAGS_HIERARCHY=$(realpath "$3")
fi

CONFIG=$(dirname "$0")/evernote_config.json
TEMPLATE=$(dirname "$0")/evernote_converted_note.template

if [ ! -d "$OUTPUT" ]
then
    echo "ERROR: The output directory $OUTPUT does not exist."
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

if [ "$TAGS_HIERARCHY" != "" ]
then
    # Create an associative array to store category/tag pairs from TAGS_HIERARCHY.
    declare -A CATEGORIES

    # Loop through each line of TAGS_HIERARCHY and split by /.
    while read line; do 
      category=${line%/*} # get the part before /
      tag=${line#*/} # get the part after /
      CATEGORIES[$tag]=$category # store the pair in the array 
    done < $TAGS_HIERARCHY
fi

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

    if [ "$TAGS_HIERARCHY" != "" ]
    then

        # Create an empty string to store the new tags line.
        NEW_TAGS=""

        # Loop through each WORD of FILE and check if it starts with tags:
        OLD_TAGS=$(head -n 50 "$FILE" | grep -e "^tags:")
        while read WORDS; do 
          for WORD in $(echo "$WORDS"); do
            if [[ $WORD == "tags:" ]]; then 
              continue 
            fi 

            # Check if the WORD is a tag that has a category in the array.
            if [[ -n ${CATEGORIES[$WORD]} ]]; then 
              NEW_TAGS="$NEW_TAGS${CATEGORIES[$WORD]}/$WORD "
            else 
              NEW_TAGS="$NEW_TAGS$WORD "
            fi 
          done

        done <<< $OLD_TAGS # Use here-string to feed WORDS from tags.

        # Replace the old tags line with NEW_TAGS in FILE using sed.
        sed -i .bak "s@^tags:.*@tags: $NEW_TAGS@" "$FILE"
    fi

    rm "$FILE".bak
done
echo "Done"
