expertTrain README
===========

Purpose
----

expertTrain is a visual category expertise training environment written in Matlab using Psychtoolbox.

About
----

- The environment supports running experiments with multiple sessions, where each session is divided into phases. Configuration files for the experiments called `EBIRD`, `EBUG`, `SPACE`, and `COMP` are included.
- There are four potential main phases for each session of `EBIRD` and `EBUG`:
   1. Old/New recognition (`recog`): study a list of targets, tested on recognizing targets and lures.
   1. Subordinate matching (`match`): decide whether two stimuli are from the same species.
   1. Naming (`name`): must press corresponding species key, and the species number is not displayed on screen.
   1. Viewing (`view`): must press corresponding species key, displayed on screen with each stimulus. **This phase is not being used.**
- There are two additional augmented introductory training phases (typically to be used on Training Day 1):
   1. Nametrain (`nametrain`): Just like the `name` phase, but species are introduced a one or two at a time (as defined in `config_EXPNAME.m`) and subjects have to name the species even if no exposure has occurred. The idea is that this will force subjects to learn the species labels quickly.
   1. Viewname (`viewname`): intermixed viewing and naming blocks (described above) for introducing the subject to different species. **This phase is not being used.**
- Another phase is included that could be used for stimulus similarity normalization (`compare`). A configuration file for a separate experiment called `COMP` is included, though the comparison task could easily be implemented in a training experiment with the correct configuration setup.
- Another experiment with its own set of phases is called `SPACE`. This is a spacing effect experiment. There are four phases:
   1. Exposure (`expo`): expose subject to stimuli and have them provide ratings. These stimuli will be shown in the `multistudy` phase.
   1. Paired associate study (`multistudy`): view paired associate stimuli (words and images).
   1. Math distractor (`distract_math`): solve math problems as a distractor task.
   1. Cued recall (`cued_recall`): cued recall for stimuli in the `multistudy` phase, with a typed response for word stimuli.
- `expertTrain` has been developed and tested under Matlab 2013a and Psychtoolbox 3.0.11 (Flavor: beta) on Mac OS X 10.8.3, as well as 10.6.8 using Matlab 2012b. It has been used extensively on Windows XP with Matlab 2013a, and to a lesser extent on Debian 7.
- **You must use a USB keyboard with this experiment.**

Installation
----

- Download and install Psychtoolbox (PTB) version 3
   - http://psychtoolbox.org/PsychtoolboxDownload
   - Make sure to add it to your Matlab path
- Download `expertTrain` to a reasonable location on your computer (e.g., `~/Documents/experiments/`)
   - You can clone with the GitHub app or regular git in Terminal, or download the zip.
   - https://github.com/warmlogic/expertTrain
   - It is **not** recommended that you add it to your Matlab path
- Acquire a stimulus image set (e.g., creatures/sheinbugs or birds)
   - Name all stimulus images using this pattern: `FamilySpeciesExemplar.extension`
      - e.g., `ab1.bmp` (family a, species b, exemplar 1); `sc2.bmp` (family s, species c, exemplar 2)
      - You can name them with single letters for family and species followed by exemplar number (as above), or:
         - the experiment supports multiple character family names, which will is useful for particular paradigms (e.g., when stimulus images are manipulated).
         - Family names can contain digits (e.g., `fam1`), but species names cannot contain digits. Exemplar numbers can only consist of digits (because any numbers in the `species+exemplarNumber` string will be read as part of the exemplar number).
   - All species exemplar images should be stored flat in a single family directory, within `expertTrain/images/STIM_SET_NAME/FAMILY_NAME/`
      - e.g., `expertTrain/images/Creatures/a/` (for family "a" images, where all images in this folder start with "a")
   - There is a creature set located on curran-lab:
      - <pre><code>/Volumes/curranlab/ExperimentDesign/Experiment Stimuli/Creatures/sorted_in_selected_not_selected.zip</code></pre>
      - NB: If you use this stimulus set and the provided config files (see "Preparing the experiment", below), you must rename the family 1 directory to "a" and the family 2 directory to "s".
   - There is a bird set located on curran-lab: `/Volumes/curranlab/ExperimentDesign/Experiment Stimuli/Birds/Birds_matt/Final Bird Stimuli` (email me or `tclab@colorado.edu` if you need help)

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
   1. Connect the behavioral testing computer and the Net Station computer together with an ethernet cable.
   1. Find the IP address of the Net Station computer (`System Prefs > Network > Ethernet`, or it's listed in the Multi-Port ECI panel in Net Station) and put the IP address in the top of the config file as the variable `expParam.NSHost` as a string.
   1. When you run the experiment, be sure to include the proper argument in the experiment command or popup window to use Net Station. (See "Running the experiment" below for more information.)
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
   - Net Station support (sending tags to NS) is fully implemented (http://docs.psychtoolbox.org/NetStation). I send an improved NetStation.m function to the PTB team in mid-summer 2013, so it is ok to use that function. (This means `et_NetStation.m` is no longer necessary.)
   - If your computer doesn't have much memory, you can choose to not preload all stimulus images by setting cfg.stim.preloadImages to `false` in the config file.
   - You can do a photocell test to determine accuracy of timing of Psychtoolbox presenting stimuli and talking to Net Station. This is done with an argument in the initial `expertTrain` command. See `help expertTrain` for details. Email `tclab@colorado.edu` if you need help with this.

Running the experiment
----

- In Matlab, `cd` into the `expertTrain` directory.
- Run the experiment: `expertTrain('EXPNAME',subNum,useNS);` (where `'EXPNAME'` is a string, `subNum` is an integer, and `useNS` is 1 or 0 (for either using Net Station to record EEG or not))
   - e.g., `expertTrain('EBUG',1,1);` runs EBUG subject 1 (called EBUG001 in the data directory) and recording with Net Station.
   - You can also run the experiment by just running the command `expertTrain;`. You are then required to enter the experiment details in a dialogue box.
   - NB: You must have `config_EXPNAME.m` set up ahead of time. See "Preparing the experiment" above.
   - Run each successive session using the same command. The experiment will pick up at the next session.
- If you just want to try out different sessions or phases of the EBUG experiment without running through the entire thing, you can edit the top of `config_EBUG.m` so that one of the debug code chunks is uncommented.
   - NB: Need to delete the subject folder every time you change `config_EBUG.m` in order to apply the changes.
- If you need to break out of the experiment while it's running, press `control-c` (might need to press it twice).
   - **IMPORTANT**: If you break out of a session, the experiment has the capability of resuming where you left off. However, it is not advisable to break out unless it can't be avoided. There is a bug with the recognition portion where the response key image gets messed up.
   - To get back to the Matlab command window:
      - If you're on Mac OS X, type `control-c` again and enter the command `sca` (blindly if you have to) to clear any remaining PTB windows.
      - If you're on Windows, first alt-tab to the Matlab application, then type `control-c` again and enter the command `sca` (blindly if you have to) to clear any remaining PTB windows.
- Debugging
   - PTB seems bad at showing actual error messages, so using multiple monitors is a good way to debug.
   - If you're running multiple monitors and you have turned on `dbstop if error`, if the experiment encounters an error you can type `dbup` and then `ME` to see the error stack trace.
   - A mat file with this same error information gets saved to the session directory in case you have not turned on `dbstop if error`. Load it and examine the `ME` variable to find your bug.
   - To get back to the Matlab command window, (Windows users: first alt-tab to Matlab) type `control-c` again and enter the command `sca` (blindly if you have to) to clear any remaining PTB windows.
- Resuming
   - The experiment can be resumed from (approximately) where it left off if it crashes. This happens automatically.

Important notes
====

- I think this has been resolved (meaning it is no longer an issue), but you're better safe than sorry. If you're running on Windows XP, it seems that you should not allow participants to push other keys along with the response key.
   - For example, do not let participants rest their hand(s) on the Control key, as the double key press may crash the experiment. This is probably too extreme, but you may want to physically remove the Control key and other modifier keys (e.g., Alt and Windows keys) from the participant keyboard.

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
      rsync -avzP --include="EBIRD**" --exclude="*" --perms --update --max-delete=0 --verbose '/cygdrive/c/Documents and Settings/curranlab/My Documents/My Experiments/expertTrain/data/' /cygdrive/z/Data/EBIRD/Behavioral/Sessions/
      cd c:\WINDOWS\system32
      attrib -h /s z:\Data\EBIRD\Behavioral\Sessions \ * . *
      </code></pre>
   1. Note that the last line (starts with "attrib") should end with: "Sessions" followed by a backslash and then asterisk-dot-asterisk, with **no spaces between these items**.
   1. Replace "EBIRD" with your experiment name.
   1. Save it in `c:\Program Files\cwRsync`
   1. Create a shortcut, move to somewhere convenient (e.g., the desktop), double-click to run.

Known Issues
====

- Resuming a partially run recognition phase (`et_recognition.m`) may cause a squashed version of the stimulus image to be presented where the response key image should be. I have no idea why this happens.

TODO
====

- Initial Eyelink eye tracking support: http://psychtoolbox.org/EyelinkToolbox

Links
====

- Project page: https://github.com/warmlogic/expertTrain
- Psychtoolbox: http://psychtoolbox.org/PsychtoolboxDownload
- My page: http://psych.colorado.edu/~mollison/

[![githalytics.com alpha](https://cruel-carlota.pagodabox.com/1ca46b4add50a53cc5a17326d3470510 "githalytics.com")](http://githalytics.com/warmlogic/expertTrain)
