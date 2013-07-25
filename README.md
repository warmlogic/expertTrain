expertTrain README
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
- expertTrain has been developed tested under Matlab 2012b and Psychtoolbox 3.0.10 (Flavor: beta) on Mac OS X 10.8.3. It has also been used on Windows XP and Debian 7 with Matlab 2013a, but to a lesser extent.
- You must use a USB keyboard with this experiment.

Installation
----

- Download and install Psychtoolbox (PTB) version 3
   - http://psychtoolbox.org/PsychtoolboxDownload
   - Make sure to add it to your Matlab path
- Download expertTrain to a reasonable location on your computer (e.g., `~/Documents/experiments/`)
   - You can clone with the GitHub app or regular git in Terminal, or download the zip.
   - https://github.com/warmlogic/expertTrain
   - It is **not** recommended that you add it to your Matlab path
- Acquire a stimulus image set (e.g., creatures/sheinbugs or birds)
   - Name stimulus images using this pattern:
      - `ab1.bmp` (family a, species b, exemplar 1); `sc2.bmp` (family s, species c, exemplar 2)
      - You should probably stick to naming with single letters for family and species followed by exemplar number (as above).
         - However, the experiment now supports multiple character family names, which will be used for when stimulus images are manipulated.
         - Family names can also contain digits (e.g., `fam1`), but species names must not contain digits and exemplar numbers can only consist of digits (because any numbers in the `species+exemplarNumber` string will be read as part of the exemplar number).
   - All species exemplar images should be stored flat in a single family directory, within `expertTrain/images/STIM_SET_NAME/FAMILY_NAME/`
      - e.g., `expertTrain/images/Creatures/a/` (for family "a" images)
   - There is a creature set located on curran-lab:
      - <pre><code>/Volumes/curranlab/ExperimentDesign/Experiment Stimuli/Creatures/sorted_in_selected_not_selected.zip</code></pre>
      - NB: If you use this stimulus set and the provided config files (see "Preparing the experiment", below), you must rename the family 1 directory to "a" and the family 2 directory to "s".
   - There is a bird set located on curran-lab: `/Volumes/curranlab/ExperimentDesign/Experiment Stimuli/Birds/Birds_matt/Final Bird Stimuli` (email me or `tclab@colorado` if you need help)

Preparing the experiment
----

- Set up a config function file for your experiment (`config_EXPNAME.m`), as well as any supporting functions or files.
   - Supporting files: the config function runs the functions `et_saveStimList()` and `et_processStims()`
   - See `expertTrain/config_EBUG.m` for an example.
      - Note how it runs `et_saveStimList()` and `et_processStims()`
      - Apologies for being such a long/extensive config file, but it is well organized.
   - For the config structures in `config_EBUG.m`, each entry in `expParam.sesTypes` is a separate session (e.g., different days of the experiment). The phases for each session are configured below that in the `expParam.session` field. The requirement is that `expParam.session` has a field for each `expParam.sesTypes` entry.
- For Net Station integration:
   1. Set up your Net Station acquisition template to have a Multi-Port ECI device between the Source device and the Recorder device, and connect the blue STIM tube through them all the way to the Display device.
   1. Set `expParam.useNS = true;` in the config file.
   1. Connect the behavioral testing computer and the Net Station computer together with an ethernet cable.
   1. Find the IP address of the Net Station computer (`System Prefs > Network > Ethernet`, or it's listed in the Multi-Port ECI panel in Net Station) and put the IP address in the top of the config file as the variable `expParam.NSHost` as a string.
   1. When Net Station is open and the experiment runs, the experiment will automatically start and stop recording EEG.
- Less well described/organized features (see examples in `config_EBUG.m` for now):
   - `et_calcExpDuration()` is a function to determine how long your experiment will be.
   - Instructions are read from external text files in `expertTrain/text/instructions/`.
   - Press the `g` key (might need to hold it for a second) to end the impedance check to continue when there is a message to the experimenter, to dismiss the final screen, etc.
   - There are practice modes for matching, naming, and recognition. Hopefully the provided config is clear enough on how to set them up. Use `expParam.runPractice=true;` to run the practice.
      - Practice stimuli can either be chosen from a separate directory of images (in the `expertTrain/images/STIM_SET_NAME/FAMILY_NAME/` directory structure, as with experiment stimuli), or they can be randomly selected from the experimental families/species. Set `cfg.stim.useSeparatePracStims` to either `true` or `false`.
   - Image manipulation conditions are supported. Use different family names for each condition. Species orders can be yoked together across families if there is something common about conditions and exemplars.
      - See `config_EBIRD.m` for an example of adding stimulus manipulation conditions.
   - Impedance breaks (every X trials [phases: matching, name] or Y blocks [phases: recognition, nametrain, viewname]).
   - Blink breaks (every X seconds)
   - Test using a previous phase's stimuli in a current phase (see the example field `usePrevPhase` in `config_EBUG.m`, e.g., `usePrevPhase = {'sesName', 'phaseName', phaseNum};`.
      - Also use the field `reshuffleStims`, which must be `true` or `false`.
   - Resize image stimuli using the field `cfg.stim.stimScale` in in `config_EBUG.m`. Set equal to the proportion of image; e.g., 1.0 = full-size image. Instruction images can be scaled as well.
   - There are multiple versions of the recognition and naming/viewing response key images (in `expertTrain/images/resources/`).
   - Net Station support (sending tags to NS) is fully implemented (http://docs.psychtoolbox.org/NetStation) but the NetStation function has been improved. Use `et_NetStation.m` instead of PTB's implementation.

Running the experiment
----

- In Matlab, `cd` into the expertTrain directory.
- Run the experiment: `expertTrain('EXPNAME',subNum,useNS);` (where `'EXPNAME'` is a string, `subNum` is an integer, and `useNS` is 1 or 0 (for either using Net Station to record EEG or not))
   - e.g., `expertTrain('EBUG',1,1);` runs EBUG subject 1 (called EBUG001 in the data directory) and recording with Net Station.
   - You can also run the experiment by just running the command `expertTrain;`. You are then required to enter the experiment details in a dialogue box.
   - NB: You must have `config_EXPNAME.m` set up ahead of time. See "Preparing the experiment" above.
   - Run each successive session using the same command. The experiment will pick up at the next session.
- If you just want to try out different sessions or phases of the EBUG experiment without running through the entire thing, you can edit the top of `config_EBUG.m` so that one of the debug code chunks is uncommented.
   - NB: Need to delete the subject folder every time you change `config_EBUG.m` in order to apply the changes.
- If you need to break out of the experiment while it's running, press `control-c` (might need to press it twice).
   - **IMPORTANT**: If you break out of a session, the experiment currently does not have the capability to resume where you were. If you start it again, it will launch at the beginning of the current session.
   - To get back to the Matlab command window, type `control-c` again and enter the command `sca` (blindly if you have to) to clear any remaining PTB windows.
- Debugging
   - PTB seems bad at showing actual error messages, so using multiple monitors is a good way to debug.
   - If you're running multiple monitors and you have turned on `dbstop if error`, if the experiment encounters an error you can type `dbup` and then `ME` to see the error stack trace.
   - A mat file with the error information gets saved to the session directory. Load it and examine the `ME` variable to find your bug.
   - To get back to the Matlab command window, type `control-c` again and enter the command `sca` (blindly if you have to) to clear any remaining PTB windows.
- Resuming
   - The experiment can be resumed from (approximately) where it left off if it crashes. This happens automatically.

Important notes
====

- I think this has been resolved (meaning it is no longer an issue), but you're better safe than sorry. If you're running on Windows XP, it seems that you should not allow participants to push other keys along with the response key.
   - For example, do not let participants rest their hand(s) on the Control key, as the double key press will crash the experiment. You may want to physically remove the Control key and other modifier keys (e.g., Alt and Windows keys) from the participant keyboard.

Convenient functions
====

Windows run-experiment batch file
----

- On Windows (only tested on XP), you can make a batch file for easily running the experiment in Matlab from, e.g., the desktop.
   1. Make a file in Notepad called `RunExpertTrain.bat` with this inside (but modify the path as appropriate for your setup):
      - <pre><code>matlab -sd "C:\Documents and Settings\curranlab\My Documents\My Experiments\expertTrain" -r "expertTrain"</code></pre>
   1. Save it in the `expertTrain` directory.
   1. Create a shortcut, move to somewhere convenient (e.g., the desktop), double-click to run.

Windows backup-data rsync function
----

- It is easy to use rsync on a Mac to backup local data to a remote server. However, this is not the case on Windows. Here's how to do it (only tested on XP):
   1. Install `cwRsync` (and maybe `Cygwin`??)
      - http://www.rsync.net/resources/howto/windows_rsync.html (second link down, not Windows Backup Agent)
   1. Make a file in Notepad called `BackupEXPNAME.cmd` with this inside, but change EXPNAME to your experiment name (e.g., EBUG or EBIRD) and modify the paths below as appropriate:
      - <pre><code>SET CWRSYNCHOME=%PROGRAMFILES%\CWRSYNC
      SET CYGWIN=nontsec
      SET CWOLDPATH=%PATH%
      SET PATH=%CWRSYNCHOME%\BIN
      rsync -a --perms --update --max-delete=0 --verbose '/cygdrive/c/Documents and Settings/curranlab/My Documents/My Experiments/expertTrain/data/' /cygdrive/z/Data/EBIRD/Behavioral/Sessions/
      cd c:\WINDOWS\system32
      attrib -h /s z:\Data\EBIRD\Behavioral\Sessions\*.*
      </code></pre>
   1. Save it in `c:\Program Files\cwRsync`
   1. Create a shortcut, move to somewhere convenient (e.g., the desktop), double-click to run.

TODO
====

- Initial Eyelink eye tracking support: http://psychtoolbox.org/EyelinkToolbox

Links
====

- Project page: https://github.com/warmlogic/expertTrain
- Psychtoolbox: http://psychtoolbox.org/PsychtoolboxDownload
- My page: http://psych.colorado.edu/~mollison/
