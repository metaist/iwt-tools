#!/usr/bin/env bash

# Copyright 2016 Metaist LLC
# MIT License

# Download files from Ramit's Brain Trust

# Dependencies: wget, aria2

# bash strict mode
set -uo pipefail
IFS=$'\n\t'

RBT_SCRIPT_NAME=${0:-""}
RBT_SCRIPT_ARGS="$@"
RBT_SCRIPT_DIR=$(dirname $(readlink -f $0))
RBT_SCRIPT_VERSION="1.0.0"

RBT_INDEX="$RBT_SCRIPT_DIR/rbt-index.txt"
RBT_NUM=""

RBT_COOKIES="$RBT_SCRIPT_DIR/cookies.txt"
RBT_NEED_LOGIN=false
RBT_USERNAME=""
RBT_PASSWORD=""

RBT_FORMAT="%num-%name.%ext"
RBT_MP3=false
RBT_MP4=false
RBT_PDF=false

RBT_URL_LOGIN="http://braintrust.iwtstudents.com/users/login"
RBT_URL_DOWNLOAD="http://braintrust.iwtstudents.com/modules/download"

RBT_USAGE="\
Usage: $RBT_SCRIPT_NAME [args]

Keyword Arguments:
  -h, --help              show usage and exit
  --version               show version and exit

Episodes:
  --index FILE            list of interviewees (default: $RBT_INDEX)
  -n NUM, --num NUM       download specific issue number

Login:
  --cookies FILE          cookie file to use for login (default: $RBT_COOKIES)
  --force-login           force login even if cookie file exists
  -u USER, --user USER    RBT username
  -p PASS, --pass PASS    RBT password (not recommended)

Download:
  --format FMT            download file name format (default: $RBT_FORMAT)
  --all                   download transcript, audio, and video
  --pdf, --transcript     download the transcript
  --mp3, --audio          download the audio
  --mp4, --video          download the video
"

# Parse command line arguments.
rbt_parse_args() {
  while [[ "$#" > 0 ]]; do
    case ${1:-''} in
      -h|--help) echo "$RBT_USAGE"; exit; break;;
      --version)
        echo "$(basename ${RBT_SCRIPT_NAME%.*}) v$RBT_SCRIPT_VERSION"
        exit 0
        break;;

      --index) RBT_INDEX=${2:-''}; shift 2;;
      -n|--num) RBT_NUM=${2:-''}; shift 2;;

      --cookies) RBT_COOKIES=${2:-''}; shift 2;;
      --force-login) RBT_NEED_LOGIN=true; shift 1;;
      -u|--user) RBT_USERNAME=${2:-''}; shift 2;;
      -p|--pass) RBT_PASSWORD=${2:-''}; shift 2;;

      --format) RBT_FORMAT=${2:-''}; shift 2;;
      --all)
        RBT_MP3=true;
        RBT_MP4=true;
        RBT_PDF=true;
        shift 1;;
      --mp3|--audio) RBT_MP3=true; shift 1;;
      --mp4|--video) RBT_MP4=true; shift 1;;
      --pdf|--transcript) RBT_PDF=true; shift 1;;

      *)
        echo "Unknown option: ${1:-''}"
        exit 1
        break;;
    esac
  done # args parsed
}

# Get credentials and perform login.
rbt_login() {
  printf "Username: "
  if [[ -z "$RBT_USERNAME" ]]; then
    read RBT_USERNAME
  else
    printf "$RBT_USERNAME"
  fi

  printf "Password: "
  if [[ -z "$RBT_PASSWORD" ]]; then
    stty -echo
    read RBT_PASSWORD
    stty echo
  fi
  printf "\n"

  wget \
    --save-cookies "$RBT_COOKIES" \
    --keep-session-cookies \
    --post-data "data[User][email]=$RBT_USERNAME&data[User][password]=$RBT_PASSWORD&data[User][remember_me]=1" \
    --delete-after \
    "$RBT_URL_LOGIN"

  # TODO: need to handle bad credentials
}


# Download a single item.
rbt_download() {
  local num=${1:-''}
  local name=${2:-''}
  local ext=${3:-''}
  local url="$RBT_URL_DOWNLOAD/interview-with-$name"
  local out="$ext/$RBT_FORMAT"
  out=${out//'%num'/"$num"}
  out=${out//'%name'/"$name"}
  out=${out//'%ext'/"$ext"}

  case "$ext" in
    pdf) url="$url/transcript_link/";;
    mp3) url="$url/audio_link/";;
    mp4) url="$url/video_download_link/";;
  esac

  if [[ ! -e "$out" || -e "$out.aria2" ]]; then
    echo "[$ext] GET #$num - $name"
    aria2c \
      --continue=true \
      --load-cookies "$RBT_COOKIES" \
      --http-accept-gzip=true \
      --summary-interval=0 \
      -o "$out" \
      "$url"
    case $? in
      0) echo "-> Downloaded";;
      3) echo "-> Not Found";;
      7) echo "Exiting..."; exit 1; break;;
      24) echo "-> Unauthorized";;
      *) echo "-> Unknown Error (#$?)"
    esac
  else
    echo "[$ext] SKIP #$num - $name"
  fi
}

rbt_parse_args "$@"

if [[ ! -f $RBT_COOKIES || "$RBT_NEED_LOGIN" == true ]]; then rbt_login; fi
# credentials stored

if [[ ! -e 'pdf' && "$RBT_PDF" == true ]]; then mkdir pdf; fi
if [[ ! -e 'mp3' && "$RBT_MP3" == true ]]; then mkdir mp3; fi
if [[ ! -e 'mp4' && "$RBT_MP4" == true ]]; then mkdir mp4; fi

while IFS="|" read -r num name
do
  if [[ -z "$num" ]]; then continue; fi
  if echo $num | egrep -q '^[^0-9]'; then continue; fi

  if [[ "$RBT_NUM" == "" || "$RBT_NUM" == "$num" ]]; then
    if [[ "$RBT_PDF" == true ]]; then rbt_download "$num" "$name" "pdf"; fi
    if [[ "$RBT_MP3" == true ]]; then rbt_download "$num" "$name" "mp3"; fi
    if [[ "$RBT_MP4" == true ]]; then rbt_download "$num" "$name" "mp4"; fi
  fi
done <$RBT_INDEX
