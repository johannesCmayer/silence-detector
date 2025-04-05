#!/bin/sh

# Dependencies: bash sox bc nix mpv dzen2 gawk bb utils.sh

SOURCE_DIR="$(dirname "${BASH_SOURCE[0]}")"
source "/home/johannes/bin/utils.sh"

create_pid_file

record_interval=1

# Sound Files
nice_sound="$SOURCE_DIR/nice_beep.opus"
buzzer="$SOURCE_DIR/wrong_buzzer.mp3"
swoosh="$SOURCE_DIR/swoosh.mp3"

silence_threshold=0.06

check_file_exists "$buzzer" "$swoosh" "$nice_sound"

soft_fail () {
    mpv "$swoosh" --vo=null >/dev/null
}

strong_fail () {
    mpv "$buzzer" --vo=null >/dev/null
}

show_dzen2_bar () {
    for i in 1 2 3 4; do
        bb -e "(use 'clojure.string) (join \" \" (repeat 1000 \"IA\"))" \
        | dzen2 -p 1 -ta l -sa c -w 10000 -h 20 -bg green -fg black -xs $i &
    done
}

success () {
    show_dzen2_bar
    mpv "$nice_sound" --vo=null >/dev/null
}

while true; do
    echo "recording ${record_interval}s of audio" >/dev/null
    sox -q -t alsa default test.wav trim 0 "$record_interval"

    # Check for total silence
    silence_result=$(sox test.wav -n stat 2>&1 | grep 'Maximum amplitude' | awk '{print $3}')

    # Determine if silence was detected (near-zero amplitude)
    if (( $(echo "$silence_result < $silence_threshold" | bc -l) )); then
        echo "The $record_interval second long recoding contanis only silence." >/dev/null
        if [ "$1" = "strong" ]; then
            strong_fail
        elif [ "$1" = "none" ]; then
            :
        elif [ "$1" = "soft" ]; then
            soft_fail
        else
            :
        fi
    else
        echo "Sound detected in the $record_interval seconds recording." >/dev/null
        success
    fi

    # Clean up recorded file
    rm -f test.wav
done
