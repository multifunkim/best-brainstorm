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


## Installation



## Citation

