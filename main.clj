#!/usr/bin/env bb
(require '[babashka.cli :as cli]
         '[babashka.fs :as fs])

(defn show-help
  [spec]
  (cli/format-opts (merge spec {:order (vec (keys (:spec spec)))})))

(def cli-spec
  {:spec
   {:num {:coerce :long
          :desc "some positive number"
          :alias :n
          :valiadte pos?
          :require true}}
   :error-fn
   (fn [{:key [spec type cause msg option] :as data}]
     (print "error"))})

(defn -main
  [args]
  (let [opts (cli/parse-opts args cli-spec)]
    (print opts)))

(-main *command-line-args)

;; SOURCE_DIR="$(dirname "${BASH_SOURCE[0]}")"
;; source "$SOURCE_DIR/utils.sh"

;; create_pid_file

;; record_interval=$1

;; nice_sound="$SOURCE_DIR/nice_beep.opus"

;; buzzer="$SOURCE_DIR/wrong_buzzer.mp3"
;; swoosh="$SOURCE_DIR/swoosh.mp3"

;; check_file_exists "$buzzer" "$swoosh"

;; (play-sound)

;; soft_fail () {
;;     mpv "$swoosh" --vo=null &
;;     # gsay --echo "IA"
;; }

;; strong_fail () {
;;     mpv "$buzzer" --vo=null
;;     # gsay --echo "IA. You wanted to talk to IA."
;; }

;; show_dzen2_bar () {
;;     for i in 1 2 3 4; do
;;         echo hello | dzen2 -p 1 -ta c -sa c -w 10000 -h 20 -bg green -xs $i &
;;     done
;; }

;; success () {
;;     show_dzen2_bar
;;     mpv "$nice_sound" --vo=null
;;     echo "Sound detected in the $record_interval seconds recording."
;; }

;; while true; do 
;;     echo "recording ${record_interval}s of audio"
;;     sox -q -t alsa default test.wav trim 0 "$record_interval" &
;;     # timer --name "silence-detector recording" "$record_interval"
;;     wait

;;     # Check for total silence
;;     silence_result=$(sox test.wav -n stat 2>&1 | grep 'Maximum amplitude' | awk '{print $3}')

;;     # Determine if silence was detected (near-zero amplitude)
;;     if (( $(echo "$silence_result < 0.03" | bc -l) )); then
;;       if [ "$1" = "strong" ]; then
;;           strong_fail
;;       else
;;           soft_fail
;;       fi
;;       echo "The $record_interval second long recoding contanis only silence."
;;     else
;;         success
;;     fi

;;     # Clean up recorded file
;;     rm -f test.wav
;; done
