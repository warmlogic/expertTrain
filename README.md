expertTrain readme
===========

Purpose
----

expertTrain is a visual category expertise training experiment written in Matlab using Psychtoolbox.

About
----

- The experiment supports running multiple sessions, and each session is be divided into phases.
- There are four possible phases in each session, and a fifth augmented view+name task:
   1. Old/New recognition (study a list of targets, tested on recognizing targets and lures)
   1. Subordinate matching (decide whether two stimuli are from the same species)
   1. Viewing (must press corresponding species key, displayed on screen with each stimulus)
   1. Naming (must press corresponding species key, not displayed on screen)
   1. Viewname (intermixed viewing and naming blocks for introducing the subject to different species)
- expertTrain has been developed tested under Matlab 2012b and Psychtoolbox 3.0.10 on Mac OS X 10.8.3.

Installation
----

- Download and install Psychtoolbox (PTB) version 3
   - http://psychtoolbox.org/PsychtoolboxDownload
   - Make sure to add it to your Matlab path
- Download expertTrain (clone with the GitHub app or regular git, or download the zip)
   - https://github.com/warmlogic/expertTrain
   - I recommend that you *do not* add it to your Matlab path
- Acquire a stimulus image set (e.g., creatures/shinebugs or birds)
   - Stimulus images should be named using this pattern:
      - ab1.bmp (family a, species b, exemplar 1); sc2.bmp (family s, species c, exemplar 2)
   - All species exemplar images should be stored flat in a single family directory, within expertTrain/images/STIM_SET_NAME/FAMILY_NAME/
      - e.g., expertTrain/images/Creatures/a/ (for family "a" images)
   - There is a creature set located on curran-lab: /Volumes/curranlab/ExperimentDesign/Experiment Stimuli/Creatures/sorted_in_selected_not_selected.zip
      - NB: need to rename the family 1 directory to "a" and the family 2 directory to "s"

Preparing the experiment
----

- Set up a config function file for your experiment (config_EXPNAME.m), as well as any supporting functions or files.
   - Supporting files: the config function runs the functions et_saveStimList() and process_EXPNAME_stimuli()
   - See expertTrain/config_EBUG.m for an example.
      - Note how it runs et_saveStimList() and process_EBUGstimuli()
      - Apologies for being such a long/extensive config file, but it is well organized.

Running the experiment
----

- In Matlab, cd into the expertTrain directory
- Run the experiment: expertTrain('EXPNAME',subNum);
   - e.g., expertTrain('EBUG',1);
   - NB: You must have config_EXPNAME.m set up ahead of time. See "Preparing the experiment" above.
   - Run each successive session using the same command. The experiment will pick up at the next session.
- If you just want to try out different sessions or phases of the EBUG experiment without running through the entire thing, you can edit the top of config_EBUG.m so that one of the debug code chunks is uncommented (and comment out the 'sesType' and 'sessions' parts directly below the debug code).
   - NB: In the experiment's current state, need to delete the subject folder every time you change config_EBUG.m in order to apply the changes
- If you need to break out of the experiment while it's running, press control-c
   - NB: If you break out of a session, the experiment currently does not have the capability to resume where you were. If you start it again, it will launch at the beginning of the current session.
   - If you're running multiple monitors and you have turned on 'dbstop if error', you can type 'db up' and then 'ME' to see the error stack trace.
   - PTB seems really awful at showing actual error messages, so using multiple monitors is a good way to debug.
   - To get back to the Matlab command window, type control-c again and then type 'sca' (blindly if you have to) and press return to remove any remaining PTB windows.

TODO
====

- Read external instruction files
- Practice mode
- Set stimulis presentation size
- Impedance breaks (with "g" key breakout)
   - During session phases (see Grit's powerpoint)?
- Breaks during long phases for blinks and for when EEG is not recorded (specifically, the matching and full naming tasks)
   - Matching: rest after every 10 trials (~48 seconds, based on powerpoint)
   - Naming: rest after every 10 trials (~51 seconds, based on powerpoint)
   - Recognition: alredy presented in blocks, but they're not short. Study (2 min) should have two breaks (every ~40 seconds) and test (~3 min) should have three breaks (every ~40 seconds).
   - Viewing: already presented in blocks, and only on training day 1, so probably don't need breaks
- Finalize recognition task response key images
- Finalize Net Station support (including host setup and 'Connect' command): http://docs.psychtoolbox.org/NetStation
- Initial Eyelink eye tracking support: http://psychtoolbox.org/EyelinkToolbox

Links
====

- Project page: https://github.com/warmlogic/expertTrain
- Psychtoolbox: http://psychtoolbox.org/PsychtoolboxDownload
- My page: http://psych.colorado.edu/~mollison/
