expertTrain readme
===========

Purpose
----

expertTrain is a visual category expertise training experiment written in Matlab using Psychtoolbox.

About
----

expertTrain has been developed tested under Matlab 2012b and Psychtoolbox 3.0.10 on Mac OS X 10.8.3.

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
      - ab1.bmp (family a, species b, exemplar 1)
   - All species exemplar images should be stored flat in a single family directory, within expertTrain/images/STIM_SET_NAME/FAMILY_NAME/
      - e.g., expertTrain/images/Creatures/a/ (for family "a" images )
   - Creatures are located on curran-lab: /Volumes/curranlab/ExperimentDesign/Experiment Stimuli/Creatures/sorted_in_selected_not_selected.zip
      - NB: need to rename the family 1 directory to "a" and the family 2 directory to "s"

Preparing the experiment
----

- Set up a config file for your experiment, as well as any supporting functions or files
   - See expertTrain/config_EBUG.m for an example (apologies for being such a long/extensive config file, but it is well organized)
   - NB: This config file should also run et_saveStimList() and process_EXPNAME_stimuli()

Running the experiment
----

- In Matlab, cd into the expertTrain directory
- Run the experiment: expertTrain('EXPNAME',subNum); (need to have config_EXPNAME.m set up ahead of time)
   - e.g., expertTrain('EBUG',1);
- If you just want to try out different portions of the EBUG experiment without running through the entire thing, you can edit the top of config_EBUG.m so that one of the debug code chunks is uncommented (and comment out the 'sesType' and 'sessions' parts directly below the debug code).
   - NB: In the experiment's current state, need to delete the subject folder every time you change config_EBUG.m in order to apply the changes
- If you need to break out of the experiment, press control-c
   - If you're running multiple monitors and you have turned on 'dbstop if error', you can type 'db up' and then 'ME' to see the error stack trace.
   - PTB seems really awful at showing actual error messages, so using multiple monitors is a good way to debug.
   - To get back to the Matlab command window, type control-c again and then type 'sca' (blindly if you have to) and press return to remove any remaining PTB windows.
   - NB: Currently, this does not have the capability to resume a session if you break out.

TODO
====

- Read external instruction files
- Practice mode
- Breaks during long phases when EEG is not being recorded (specifically, the matching task)

Links
====

- Project page: https://github.com/warmlogic/expertTrain
- Psychtoolbox: http://psychtoolbox.org/PsychtoolboxDownload
- My page: http://psych.colorado.edu/~mollison/
