expertTrain readme
===========

Purpose
----

expertTrain is an expertise training experiment written in Matlab using Psychtoolbox. It has been tested under Matlab 2012b and Psychtoolbox 3.0.10.

Installation
----

- Download and install Psychtoolbox version 3
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

Links
====

- Project page: https://github.com/warmlogic/expertTrain
- Psychtoolbox: http://psychtoolbox.org/PsychtoolboxDownload
- My page: http://psych.colorado.edu/~mollison/
