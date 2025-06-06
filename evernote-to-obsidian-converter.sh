#!/usr/bin/env zsh
#
# This file uses YARLE to convert an Evernote .enex file
# to an Obsidian readable Markdown file system.

# ----------------
# Check input parameters
# ----------------

echo "Evernote to Obsidian converter."
if [[ $# -lt 2 ]]
then
    echo "Usage: $(basename $0) output-dir [tags-hierarchy-file.txt] file1.enex file2.enex ..."
    echo ""
    echo "  The output directory can be a full or relative path and should point at an empty"
    echo "  directory. The directory is not created by the script if it does not exist."
    echo ""
    echo "  The tags hierarchy file is optional. If provided, it must have the extension .txt and"
    echo "  contain one category/tag pair per line."
    echo ""
    echo "  Tags found in the markdown metadata of Evernote records will be prefixed by the"
    echo "  corresponding category in the tags file (or left as-is if there is not category)."
    echo ""
    echo "  The .enex files can be in the current directory, or may include a path."
    echo ""
    echo "  Example of usage:"
    echo "    $(basename $0) output ~/obsidian/mytags.txt *.enex"
    echo ""
    echo "  Example of tags file:"
    echo "       mytags.txt   == companies/apple"
    echo "       mynote.md    == ---\\ntags: apple ..."
    echo ""
    echo "     This would replace the tags line in mynote.md to:"
    echo "       mynote.md    == ---\\ntags: companies/apple ..."
    exit -1
fi

# Check if NPX was installed.
which npx >/dev/null
if [[ $? -ne 0 ]]
then
    echo "This script requires 'npx' to be installed'."
    echo ""
    echo "On a Mac, you might want to install 'brew' first, see https://brew.sh."
    echo "Then:"
    echo "  brew install node       (to install Node.js)"
    echo "  brew install npm        (to install NPM, the package manager)"
    echo "  npm install -g npx      (to install NPX, not in home directory)"
    exit -1
fi

CONFIG="$(dirname "$0")/evernote_config.json"
echo "Configuration template: $CONFIG.template"
if [[ ! -f "$CONFIG.template" ]]
then
    echo "ERROR: The configuration file template $CONFIG.template cannot be found."
    exit -1
fi

TEMPLATE="$(dirname "$0")/evernote_converted_note.template"
echo "Template: $TEMPLATE"
if [[ ! -f "$TEMPLATE" ]]
then
    echo "ERROR: The note template file $TEMPLATE cannot be found."
    exit -1
fi

OUTPUT="$1"
echo "Output: $OUTPUT"
if [[ ! -d "$OUTPUT" ]]
then
    echo "ERROR: The output directory $OUTPUT does not exist."
    echo "       Please check if it's correct, or create it first."
    exit -1
fi
shift

TAGS_HIERARCHY=
for ARG in "$@"
do
    if [[ "$ARG" == *.txt ]]
    then
        TAGS_HIERARCHY="$(realpath "$ARG")"
        if [[ -f "$TAGS_HIERARCHY" ]]
        then
            echo "Tags hierarchy: $TAGS_HIERARCHY"

            # Read tags hierarchy, to convert "x/y" tags to a proper hierarchy.
            # Create an associative array to store category/tag pairs from TAGS_HIERARCHY.
            declare -A CATEGORIES

            # Loop through each line of TAGS_HIERARCHY and split by /.
            while read LINE
            do
              CAT=${LINE%/*}
              TAG=${LINE#*/}
              CATEGORIES[$TAG]=$CAT
            done < "$TAGS_HIERARCHY"
        else
            echo "ERROR: $TAGS_HIERARCHY not found..."
            exit -1
        fi
    elif [[ "$ARG" != *.enex ]]
    then
        echo "ERROR: $ARG is not an .enex file..."
        exit -1
    fi
done


for INPUT in "$@"
do
    if [[ "$INPUT" == *.enex ]]
    then
        if [[ ! -f "$INPUT" ]]
        then
            echo "ERROR: The input file $INPUT cannot be found."
            exit -1
        fi
        echo "Input path: $INPUT"
        INPUT_BASENAME="$(basename "$INPUT")"

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

        echo "Input file (Evernote): $INPUT_BASENAME ("$(dirname "$INPUT")")"
        echo "Running Yarle..."
        npx -p yarle-evernote-to-md@latest yarle --configFile "$CONFIG"
        if [[ $? -ne 0 ]]
        then
            echo "WARNING: an error may have occurred while converting"
            echo "         $INPUT to directory $OUTPUT"
            exit 1
        fi

        # ----------------
        # Run post-conversion scripts
        # ----------------

        MD_DIR="$OUTPUT/notes/"$(basename "$INPUT" .enex)
        echo "Run post-processing scripts in $MD_DIR..."
        if [[ ! -d "$MD_DIR" ]]
        then
            echo "ERROR: Missing output directory $MD_DIR"
            exit 1
        fi
        pushd "$MD_DIR"

        # Process all Markdown files.
        for FILE in *.md
        do
            echo "Post-process: $FILE"
            # Embed <<...>> links in backticks.
            sed -i .bak 's/<<\([^>]*\)>>/`<<\1>>`/g' "$FILE"

            # Remove whitespace before tables.
            sed -i .bak 's/^[	 ]*|\(.*\)|[	 ]*$/|\1|/' "$FILE"

            if [[ -f "$TAGS_HIERARCHY" ]]
            then
                # Create an empty string to store the new tags line.
                NEW_TAGS=""

                # Loop through each WORD of FILE and check if it starts with tags:
                OLD_TAGS="$(head -n 50 "$FILE" | grep -e "^tags:")"
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

                done <<< "$OLD_TAGS" # Use here-string to feed WORDS from tags.

                # Replace the old tags line with NEW_TAGS in FILE using sed.
                sed -i .bak "s@^tags:.*@tags: $NEW_TAGS@" "$FILE"
            fi

            rm "$FILE".bak
        done
        popd
    fi
done
echo "Done"
