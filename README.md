expertTrain readme
===========

Purpose
----

expertTrain is a visual category expertise training experiment written in Matlab using Psychtoolbox.

About
----

- The experiment supports running multiple sessions, and each session is divided into phases.
- There are four main phases for each session:
   1. Old/New recognition (`recog`): study a list of targets, tested on recognizing targets and lures.
   1. Subordinate matching (`match`): decide whether two stimuli are from the same species.
   1. Naming (`name`): must press corresponding species key, and the species number is not displayed on screen.
   1. Viewing (`view`): must press corresponding species key, displayed on screen with each stimulus. **This phase is not being used.**
- There are two additional augmented introductory training phases (typically to be used on Training Day 1):
   1. Nametrain (`nametrain`): Just like the `name` phase, but species are introduced a one or two at a time (as defined in `config_EXPNAME.m`) and subjects have to name the species even if no exposure has occurred. The idea is that this will force subjects to learn the species labels quickly.
   1. Viewname (`viewname`): intermixed viewing and naming blocks (described above) for introducing the subject to different species. **This phase is not being used.**
- expertTrain has been developed tested under Matlab 2012b and Psychtoolbox 3.0.10 (Flavor: beta) on Mac OS X 10.8.3.

Installation
----

- Download and install Psychtoolbox (PTB) version 3
   - http://psychtoolbox.org/PsychtoolboxDownload
   - Make sure to add it to your Matlab path
- Download expertTrain (clone with the GitHub app or regular git, or download the zip)
   - https://github.com/warmlogic/expertTrain
   - I recommend that you **do not** add it to your Matlab path
- Acquire a stimulus image set (e.g., creatures/sheinbugs or birds)
   - Name stimulus images using this pattern:
      - `ab1.bmp` (family a, species b, exemplar 1); `sc2.bmp` (family s, species c, exemplar 2)
      - You should probably stick to naming with single letters for family and species followed by exemplar number (as above).
         - However, the experiment now supports multiple character family names, which will be used for when stimulus images are manipulated.
         - Family names can also contain digits (e.g., `fam1`), but species names must not contain digits and exemplar numbers can only consist of digits (because any numbers in the `species+exemplarNumber` string will be read as part of the exemplar number).
   - All species exemplar images should be stored flat in a single family directory, within `expertTrain/images/STIM_SET_NAME/FAMILY_NAME/`
      - e.g., `expertTrain/images/Creatures/a/` (for family "a" images)
   - There is a creature set located on curran-lab: `/Volumes/curranlab/ExperimentDesign/Experiment Stimuli/Creatures/sorted_in_selected_not_selected.zip`
      - NB: If you use this stimulus set and the provided config files (see "Preparing the experiment", below), you must rename the family 1 directory to "a" and the family 2 directory to "s".

Preparing the experiment
----

- Set up a config function file for your experiment (`config_EXPNAME.m`), as well as any supporting functions or files.
   - Supporting files: the config function runs the functions `et_saveStimList()` and `et_processStims_EXPNAME()`
   - See `expertTrain/config_EBUG.m` for an example.
      - Note how it runs `et_saveStimList()` and `et_processStims_EBUG()`
      - Apologies for being such a long/extensive config file, but it is well organized.
- Less well organized features:
   - Reading external text files containing phase instructions
   - There are practice modes for matching, naming, and recognition. Hopefully the provided config is clear enough on how to set them up.
   - Image manipulation conditions are supported, just use different family names for each condition. Species orders can be yoked together across families if there is something common about conditions and exemplars.
   - Impedance breaks (every X trials or Y blocks). Use "g" key to end the impedance check.
   - Blink breaks (every X seconds)

Running the experiment
----

- In Matlab, cd into the expertTrain directory
- Run the experiment: `expertTrain('EXPNAME',subNum);`
   - e.g., `expertTrain('EBUG',1);`
   - NB: You must have `config_EXPNAME.m` set up ahead of time. See "Preparing the experiment" above.
   - Run each successive session using the same command. The experiment will pick up at the next session.
- If you just want to try out different sessions or phases of the EBUG experiment without running through the entire thing, you can edit the top of `config_EBUG.m` so that one of the debug code chunks is uncommented (and comment out the `sesType` and `sessions` parts directly below the debug code).
   - NB: In the experiment's current state, need to delete the subject folder every time you change `config_EBUG.m` in order to apply the changes
- If you need to break out of the experiment while it's running, press `control-c`
   - NB: If you break out of a session, the experiment currently does not have the capability to resume where you were. If you start it again, it will launch at the beginning of the current session.
   - To get back to the Matlab command window, type `control-c` again and then type `sca` (blindly if you have to) and press return to remove any remaining PTB windows.
- Debugging
   - If you're running multiple monitors and you have turned on `dbstop if error`, if the experiment encounters an error you can type `db up` and then `ME` to see the error stack trace.
   - PTB seems bad at showing actual error messages, so using multiple monitors is a good way to debug.
   - To get back to the Matlab command window, type `control-c` again and then type `sca` (blindly if you have to) and press return to remove any remaining PTB windows.

TODO
====

- Test using a previous phase's stimuli in a current phase (initial support has been included)
- Resize image stimuli
- Finalize recognition task response key images
- Finalize Net Station support: http://docs.psychtoolbox.org/NetStation
- Initial Eyelink eye tracking support: http://psychtoolbox.org/EyelinkToolbox

Links
====

- Project page: https://github.com/warmlogic/expertTrain
- Psychtoolbox: http://psychtoolbox.org/PsychtoolboxDownload
- My page: http://psych.colorado.edu/~mollison/
