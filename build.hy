(import sys)
(import os)
(import pathlib [Path])
(require hyrule [with])

(setv output-directory (Path (get os.environ "out")))
(setv output-bin-path (/ output-directory "bin/vocal-reward"))

(.mkdir (. output-bin-path parent) :parents True :exist_ok True)

(with [f (open output-bin-path / "wt")]
  (.write f "echo hello2"))
