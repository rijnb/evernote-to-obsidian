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
