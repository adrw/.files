## Reformatting Audio Books for iPod

- Use `brew cask install mediahuman-audio-converter` to compress the files with the following settings
  - 24kbps
  - Mono
  - AAC Audio
  - m4b file
  - 22.050 khz sample
- Rename files in Finder to a author/book identifier followed by counter to signify part number. A reduction in length allows it to appear on the iPod screen.

  ```
  12 Rules for Life An Antidote to Chaos (Unabridged) - 01.m4a

  ->

  JBP 12 Rules 00001.m4a
  ```

- Use `zmv` to rename all files to m4b to enable Audiobook functionality like progress tracking
  - Example command `zmv '*.m4a' '\$(basename \$f .m4a).m4b'`
- Use `brew cask install musicbrainz-picard` to set the file metadata using the filename
  - `Tools -> Tags from File Names`
  - Manually set Artist, Album to ensure consistency
  - Remove unnecessary additional fields including Track Number
  - `Save` to overwrite the metadata in the tracks
- Import into iTunes, the `m4b` extension should automatically imply the Audiobook type
