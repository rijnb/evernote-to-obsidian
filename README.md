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

