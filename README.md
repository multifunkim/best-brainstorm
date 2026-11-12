# Brain Entropy in space and time (BEst)

![BEst](https://neuroimage.usc.edu/brainstorm/Tutorials/TutBEst?action=AttachFile&do=get&target=BEst.jpg)

This package implements a method for estimating brain activity from MEG/EEG and/or fNIRS data.
The package proposes three methods:

- cMEM: Standard MEM with stable clustering source localization in the time-domain. The originality of this method is its ability to recover the spatial extent of the underlying sources. 

- wMEM: Wavelet-based MEM dedicated to source localization of oscillatory patterns in the time-frequency domain. The data and the solution are expressed in a discrete wavelet expansion. 

- rMEM: Ridge MEM dedicated to localize cortical sources exhibiting synchrony. Continuous complex-valued wavelet analysis of the data allows detection of data segments exhibiting synchrony between sensors. rMEM consists in localizing the generators of these detected synchrony patterns.

## Tutorials

- Brainstorm tutorial: [BEst](https://neuroimage.usc.edu/brainstorm/Tutorials/TutBEst)
- Brainstorm tutorial: [Epilepsy - Source localization of epileptic activity](https://neuroimage.usc.edu/brainstorm/Tutorials/Epilepsy#A.28Advanced.29_Source_analysis:_MEM_inverse_solution)
- Brainstorm tutorial: [NIRSTORM – inverse problem using cMEM](https://neuroimage.usc.edu/brainstorm/Tutorials/NIRSTORM#Inverse_problem_using_cMEM)


## Usage

The recommended way to use MEM is from Brainstorm. For more information follow the [BEst tutorial](https://neuroimage.usc.edu/brainstorm/Tutorials/TutBEst). MEM is also available through MNE-Python: see https://github.com/multifunkim/best-python for details. MATLAB is required.


## References
The references to be acknowledged for each method are:

- **cMEM with stable clustering**. [MEG source localization of spatially extended generators of epileptic activity: comparing entropic and hierarchical bayesian approaches.](http://www.ncbi.nlm.nih.gov/pubmed/23418485) Chowdhury RA, Lina JM, Kobayashi E, Grova C. PLoS One. 2013;8(2):e55969

- **wMEM**. [Wavelet-based localization of oscillatory sources from magnetoencephalography data.](http://www.ncbi.nlm.nih.gov/pubmed/22410322) Lina J, Chowdhury R, Lemay E, Kobayashi E, Grova C. IEEE Trans Biomed Eng. 2012 Mar 6.

Additional technical references:

- **MEM**. [Biomagnetic source detection by maximum entropy and graphical models.](http://www.ncbi.nlm.nih.gov/pubmed/15000374) Amblard C, Lapalme E, Lina JM. IEEE Trans Biomed Eng. 2004 Mar;51(3):427-42.

- **MEM and Parcelization**. [Data-driven parceling and entropic inference in MEG.](http://www.ncbi.nlm.nih.gov/pubmed/16426867) Lapalme E, Lina JM, Mattout J. Neuroimage. 2006 Mar;30(1):160-71.

- **MSP**. [Multivariate source prelocalization (MSP): use of functionally informed basis functions for better conditioning the MEG inverse problem.](http://www.ncbi.nlm.nih.gov/pubmed/15907296) Mattout J, Pélégrini-Issac M, Garnero L, Benali H. Neuroimage. 2005 Jun;26(2):356-73.

Validation and applications:

- [Evaluation of EEG localization methods using realistic simulations of interictal spikes.](http://www.ncbi.nlm.nih.gov/pubmed/16271483) Grova C, Daunizeau J, Lina JM, Bénar CG, Benali H, Gotman J. Neuroimage. 2006 Feb 1;29(3):734-53.

- [Concordance between distributed EEG source localization and simultaneous EEG-fMRI studies of epileptic spikes.](http://www.ncbi.nlm.nih.gov/pubmed/17945511) Grova C, Daunizeau J, Kobayashi E, Bagshaw AP, Lina JM, Dubeau F, Gotman J. Neuroimage. 2008 Jan 15;39(2):755-74

- [Spatial correlation of hemodynamic changes related to interictal epileptic discharges with electric and magnetic source imaging.](http://www.ncbi.nlm.nih.gov/pubmed/24615912) Heers M, Hedrich T, An D, Dubeau F, Gotman J, Grova C, Kobayashi E. Hum Brain Mapp. 2014 Feb 24.

- [Optimal eye-gaze fixation position for face-related neural responses.](http://www.ncbi.nlm.nih.gov/pubmed/23762224) Zerouali Y, Lina JM, Jemel B. PLoS One. 2013 Jun 6;8(6):e60128.

- [Oscillatory activity in parietal and dorsolateral prefrontal cortex during retention in visual short-term memory: additive effects of spatial attention and memory load.](http://www.ncbi.nlm.nih.gov/pubmed/19384891) Grimault S, Robitaille N, Grova C, Lina JM, Dubarry AS, Jolicoeur P. Hum Brain Mapp. 2009 Oct;30(10):3378-92.
