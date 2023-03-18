# Evernote to Obsidian conversion script

To convert an Evernote database to a Obsidian (Markdown-based) vault:

1. Export your Evernote notebook to an .enex file.
2. Create an output directory for conversion results.
3. Execute the conversion script:

```
evernote-to-obsidian-converter.sh <output-dir> <.enex-file>
```

This script:

* Executes Yarle with a generated configuration file.
* Embeds incorrect `<<...>>` in backticks.
* Unindents accidentally indented Markdown tables.

## Installing and executing

To use this script, simply clone this Github repo to your
machine, like:

```
git clone https://github.com/rijnb/evernote-to-obsidian.git
```

Then:

- Optionally, add the `evernote-to-obsidian` path to your `PATH` environment
variable to easily start the `.sh` script.

- Export your Evernote notebook by right-clicking on it and choosing
"Export notebook". Select "ENEX format" and leave all options selected.

- Create an output directory for the resulting Markdown files and
attachements.

- Execute `evernote-to-obsidian.sh <output-dir> <enex-file>`, where you specify the
output directory and the `.enex` file on the commandline.

- After the conversion ends, start Obsidian and open the directory called
`notes` as your vault (or the directory with the name of the notebook, depending
on whether you want to add more notebooks later, or not).

## Converting multiple files

Converting multiple ENEX files is simply done with commands like `find` and `xargs`. 
For example:

```
find . -name "*.enex" -print0 | xargs -0 -n1 -I{} evernote-to-obsidian-converter.sh output {} ~/source/rijnb/evernote-to-obsidian/personal_tags_hierarchy.txt
```

## Tweaking the conversion

The conversion configuration can be adapted by changing values in the file
`evernote-config.json.template`. The parameters are all explained in (the Yarle config section)[https://github.com/akosbalasko/yarle].

There are 3 template parameters that will be replaced by the Zsh script:

- `@INPUT`: this will be replaced by the `.enex` filename,
- `@TEMPLATE`: this will be replaced by the note conversion template file `evernote_converted_note.template`, and
- `@OUTPUT`: this will be replaced by the output directory.

You can modify this JSON file to your liking. In its current form, tags will be hashless
as the note will contain all tags in the metadata section, without tags.

The converted notes will use the template `evernote_converted_note.template`, which contains 1 template parameter:

- `@IMPORT`: this will be replaced by the name of the imported notebook.

You can modify the note conversion template. In its current form, tags are placed on top, in the metadata section and the note will have an "Imported from Evernote" callout, with some conversion data.

## Recommended Obisidian plugins after conversion

To check the correctness of your Obsidian vault, you may want to use the
Obisidian plugins 
- Find unlinked file: [https://github.com/Vinzent03/find-unlinked-files] to identify orphaned files (make sure you exclude `md` files), and
- Vault statistics: [https://github.com/bkyle/obsidian-vault-statistics-plugin] to show you a note count (should match Evernotes note count).
