manga2mobi
==========

manga2mobi is a script to download manga and generate .mobi file as output (for reading manga on Kindle devices).

## Dependency

- [jq](https://stedolan.github.io/jq/download/): command-line JSON processor
- [kcc](https://github.com/ciromattia/kcc): Kindle Comic Converter
- [fzf](https://github.com/junegunn/fzf): command-line fuzzy finder
- [pup](https://github.com/EricChiang/pup): command-line html parser

## Supported manga source

- [MangaLife](https://manga4life.com/)
- [Kissmanga](https://kissmanga.org/)

## How to use

```
Usage:
  ./manga2mobi.sh -s <manga_slug> -c <chapter_num1,num2...> -k -d -f <source>

Options:
  -s <manga_slug>   Search and find manga slug by manga slug
                    Attention: slug name is case sensitive
  -c <num1,num2...> Specify chapter id to download
                    Multiple numbers sepereated by ","
  -k                Optinal, keep downloaded manga images
  -d                Optinal, only download manga images, without converting mobi
                    This option will apply -k automatically
  -f <source>       Optinal, from which manga source
                    available source: mangalife, kissmanga
                    mangalife is set by default
  -h | --help       Display this help message
```

### Example

- Search manga slug of "Goblin Slayer", then select the correct one in fzf:

```
~$ ./manga2mobi.sh
> goblin slayer
[Goblin-Slayer] Goblin Slayer (["Goblin Slayer"])
[Goblin-Slayer-Side-Story-Year-One] Goblin Slayer Side Story...
...
```

- Simply list "Onepunch Man" chapters, in case when you knew manga slug already. Be careful that manga slug is case sensitive:

```
~$ ./manga2mobi.sh -s Onepunch-Man
...
Chapter [125]: 2020-01-10 21:33:08
Chapter [126]: 2020-01-24 20:50:57
Chapter [127]: 2020-02-08 03:28:35
Chapter [127.2]: 2020-02-21 22:57:54
Chapter [128]: 2020-03-09 20:25:48
```

- Download "Goblin Slayer" chapter 45, all images, without converting mobi file:

```
~$ ./manga2mobi.sh -s Goblin-Slayer -c 45 -d
```

- Download "Goblin Slayer" chapter 45 and convert it to mobi file, without keeping downloaded images:

```
~$ ./manga2mobi.sh -s Goblin-Slayer -c 45
```

- Download "Onepunch Man" chapter 120, 123 and 128, then convert them to mobi files, and keep download images:

```
~$ ./manga2mobi.sh -s Goblin-Slayer -c 120,123,128 -k
```

- Switch manga source to kissmanga:

```
~$ ./manga2mobi.sh -k kissmanga
```

## Disclaimer

The purpose of this script is to download mangas in order to read them later in case when Internet is not available. Please do NOT copy or distribute downloaded mangas to any third party. Read them and delete them afterwards. Please use this script at your own responsibility.
