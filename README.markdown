# iwt-tools
_Tools for I Will Teach courses._

## Why?
On 01 Dec 2016, Ramit Sethi annouced he's shutting down Ramit's Brain Trust (RBT) and that everyone should download past interviews before 30 Dec 2016. So I wrote a small tool that would download the interviews overnight and could resume downloading if the connection died.

I plan on extending this to other IWT courses like Earn1K (E1K) and Dream Job (DJ) in the future.

## Questions & Issues
If no one [has mentioned it before][gh-issues-all], [let me know][gh-issues].

## Install
You will first need `wget` and `aria2`. In theory, these scripts are POSIX-compliant, but I've only tested them with Linux.

On Debian-based systems you can execute:
```bash
sudo apt-get install -y wget aria2
```

Next, [download the code][gh-code] or clone the repository:
```bash
git clone https://github.com/metaist/iwt-tools.git
cd iwt-tools
```

For now, only `rbt.sh` is supported.

## Usage
```
Usage: ./rbt.sh [args]

Keyword Arguments:
  -h, --help              show usage and exit
  --version               show version and exit

Episodes:
  --index FILE            list of interviewees (default: rbt-index.txt)
  -n NUM, --num NUM       download specific issue number

Login:
  --cookies FILE          cookie file to use for login (default: cookies.txt)
  --force-login           force login even if cookie file exists
  -u USER, --user USER    RBT username
  -p PASS, --pass PASS    RBT password (not recommended)

Download:
  --format FMT            download file name format (default: %num-%name.%ext)
  --all                   download transcript, audio, and video
  --pdf, --transcript     download the transcript
  --mp3, --audio          download the audio
  --mp4, --video          download the video
```

### Notes
- `--index` uses a special index file. See [rbt-index.txt][https://github.com/metaist/iwt-tools/blob/master/rbt-index.txt] for an example.
- `--num` is 1-index; you can get the first issue using `-n 1`
- `--cookies` is a combination of whatever `wget` and `aria2c` accept.
- `--pass` should not be given on the command-line, but it's there for convenience.
- `--format` uses `%num` for the issue number, `%name` for the interviewee name, and `%ext` for the appropriate file format (`pdf`, `mp3`, or `mp4`).
- When downloading, files will be stored in a directory with the name of the file extension.

## License
Licensed under the [MIT License][osi-mit].

[gh-code]: https://github.com/metaist/iwt-tools/zipball/master
[gh-issues]: https://github.com/metaist/iwt-tools/issues
[gh-issues-all]: https://github.com/metaist/iwt-tools/issues/search?q=
[osi-mit]: http://opensource.org/licenses/MIT
