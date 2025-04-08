(import sys)
(import os)
(import shutil)
(import pathlib [Path])

(setv hy-executable (Path (get os.environ "hyExecutable")))

(setv output-directory (Path (get os.environ "out")))
(setv output-bin-path (/ output-directory "bin/vocal-reward"))

(setv main-file (Path (get os.environ "main")))

(.mkdir (. output-bin-path parent) :parents True :exist_ok True)

(with [output-file (open output-bin-path "wt")]
  (.write output-file f"#!{hy-executable}\n")
  (with [src-file (open main-file "rt")]
    (.write output-file (.read src-file))))

(os.chmod output-bin-path 0744)
