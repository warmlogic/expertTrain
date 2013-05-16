expertTrain readme
===========

Purpose
----

expertTrain is an expertise training experiment written in Matlab using Psychtoolbox. It has been tested under Matlab 2012b and Psychtoolbox 3.0.10.

Installation
----

- Download and install Psychtoolbox (PTB) version 3
   - http://psychtoolbox.org/PsychtoolboxDownload
   - Make sure to add it to your Matlab path
- Download expertTrain from GitHub (clone with git or download the zip)
   - https://github.com/warmlogic/expertTrain
   - I recommend that you *do not* add it to your Matlab path
- Acquire a stimulus image set (e.g., creatures/shinebugs or birds)
   - Stimulus images should be named using this pattern:
      - ab1.bmp (family a, species b, exemplar 1)
   - All species exemplar images should be stored flat in a single family directory, within expertTrain/images/STIM_SET_NAME/FAMILY/
      - e.g., expertTrain/images/Creatures/a/ (for family "a" images )

Preparing the experiment
----

- Set up a config file for your experiment, as well as any supporting files
   - See expertTrain/config_EBUG.m for an example
   - This also runs et_saveStimList() and process_EBUG_stimuli()

Running the experiment
----

- In Matlab, cd to the expertTrain directory
- Run the experiment: expertTrain('EXPNAME',subNum);
   - e.g., expertTrain('EBUG',1);
- To break out of the experiment, press control-c
   - If you're running multiple monitors and you have turned on 'dbstop if error', you can type 'db up' and then 'ME' to see the error stack trace.
   - PTB seems really awful at showing actual error messages, so using multiple monitors is one good way to debug.
   - To get back to the Matlab command window, type control-c again and then type 'sca' (blindly if you have to) and press return to remove any remaining PTB windows.


TODO
====

- Read external instruction files
- Practice mode
- Breaks during long phases (i.e., matching) when EEG is not being recorded

Links
====

- Project page: https://github.com/warmlogic/expertTrain
- Psychtoolbox: http://psychtoolbox.org/PsychtoolboxDownload
- My page: http://psych.colorado.edu/~mollison/
