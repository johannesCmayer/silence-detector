(import functools [reduce])
(import pymicro_vad [MicroVad])
(import pyaudio)
(import time [time])
(import subprocess [Popen PIPE TimeoutExpired])
(import threading [Thread])
(import os)

(setv
  CHUNK 160
  FORMAT pyaudio.paInt16
  CHANNELS 1
  RATE 16000
  RECORD-SECONDS 0.010
  speech-threshold 0.995
  min-time-between-rewards 1.5
  banner-display-duration 1)

;; We as a hack pass the path to the sound file when build with nix as an environment variable
(setv sound-path-nice-beep (if (in "nice_beep" os.environ)
                               (get os.environ "nice_beep")
                               "./nice_beep.mp3"))

(print (os.getcwd))
(print sound-path-nice-beep)

(defmacro when-main [#* body]
  `(when (= __name__ "__main__")
     (do ~@body)))

(defn get-device-count [pyaudio-instance]
  (get (.get_host_api_info_by_index pyaudio-instance 0)
       "deviceCount"))

(defn get-default-device-index [pyaudio-instance]
  (for [i (range (get-device-count pyaudio-instance))]
    (let [device-info
          (.get-device-info-by-host-api-device-index
            pyaudio-instance 0 i)]
      (when (= (get device-info "name")
               "default")
        (return (get device-info "index"))))))

(defn initialize-context []
  "Create audio recording context."
  (let [pyaudio-instance (pyaudio.PyAudio)]
    {:vad (MicroVad)
     :pyaudio-instance pyaudio-instance
     :audio-stream (pyaudio-instance.open
                     :input-device-index (get-default-device-index
                                           pyaudio-instance)
                     :format FORMAT
                     :channels CHANNELS
                     :rate RATE
                     :input True
                     :frames_per_buffer CHUNK)}))

(defn cleanup [context]
  (.stop_stream (get context :audio-stream))
  (.close (get context :audio-stream))
  (.terminate (get context :pyaudio-instance)))

(defn get-audio [context]
  (.read (get context :audio-stream) CHUNK))

(defn detect-speech [context]
  "Process 10ms chunks of 16-bit mono PCM @16Khz, and returns the
average speech activation."
  (let [audio (get-audio context)
        audio-length (len audio)]
    (assert (= audio-length (* 160 2))) ;; Each Int16 is 2 bytes wide.
    (.Process10ms (get context :vad) audio)))

(defn play-audio [path]
  (Popen ["mpv" "--no-video" path] :stdout PIPE :stderr PIPE))

(setv banner-msg (+ (str.join " " (* 400 ["IA"])) "\n"))

(defn dzen2-reward-banner []
  ;; We first create and then spawn the threads because python is slow.
  (for [monitor-idx (range 1 5)]
    (let [proc (Popen [f"echo '{banner-msg}' | \
                         dzen2 \
                         -p {(str banner-display-duration)} \
                         -ta l \
                         -sa c \
                         -w 10000 \
                         -h 20 \
                         -bg green \
                         -fg black \
                         -xs {monitor-idx}"]
                      :shell True)])))

(defn reward-for-speaking-loop []
  (let [context (initialize-context)
        last-beep-time (time)]
    (while True
      (let [speech-activity (detect-speech context)]
        #_(let [activity (int (max 0
                                   (- (* speech-activity 10000)
                                      9900)))]
            (print f"{(.ljust (str speech-activity) 22)} || {(* activity "=")}{(* (- 100 activity) " ")}||"))
        (when (and (> speech-activity
                      speech-threshold)
                   (> (- (time) last-beep-time)
                      min-time-between-rewards))
          (setv last-beep-time (time))
          (play-audio sound-path-nice-beep)
          (dzen2-reward-banner))))
    (cleanup context)))

(when-main
  (reward-for-speaking-loop))

;; TODO
;; - make flake provide executable
;; - make flake proivde system service
;; - make flake provide configuration options
;; - install service in nix and disable previous service
;; - [X] delete all unneeded files in repo
