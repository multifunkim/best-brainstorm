# Brain Entropy in space and time (BEst)

![BEst](https://neuroimage.usc.edu/brainstorm/Tutorials/TutBEst?action=AttachFile&do=get&target=BEst.jpg)


This plugin implements a method for estimating brain activity and functional connectivity from MEG/EEG and/or NIRS data using entropy-based measures in space and time.

BEst is designed to work within the Brainstorm environment and provides a complete pipeline for:

- importing and processing time series data,
- computing and visualizing brain maps,
- solving the inverse problem with entropy-based regularization,
- estimating source-space interactions and dynamic connectivity,
- comparing results across conditions and subjects.

The method is described in the Brainstorm tutorials for BEst and NIRSTORM.

## Installation

Install this plugin in Brainstorm following the standard plugin installation procedure:

1. Clone or copy the plugin into the Brainstorm plugins folder.
2. Restart Brainstorm.
3. Make sure the plugin is detected in the Brainstorm plugin list.
4. Update the Brainstorm path if needed.

The plugin is organized as a standard Brainstorm plugin and is available through the Brainstorm graphical interface.

## Main features

### 1) Brain entropy in space and time

The BEst approach models brain activity as a spatially sparse and temporally structured process. Instead of relying only on classical L2 or minimum-norm regularization, the method adds entropy-based constraints to balance explainability and complexity in the source estimates.

Key ideas:

- estimate sources in the brain volume or cortex,
- regularize the inverse solution with entropy-related terms,
- favor spatially distributed or sparse solutions depending on the selected formulation,
- track temporal dynamics through entropy measures.

### 2) Inverse problem using cMEM

The plugin integrates methods related to the cMEM inverse problem described in the NIRSTORM tutorial. The cMEM formulation is used for modeling brain activity from optical data and can be combined with source localization constraints adapted to the spatial and temporal structure of the signal.

In practice, this involves:

- defining a forward model (head model and leadfield),
- computing source estimates from sensor data,
- using regularization and noise modeling to stabilize the inversion,
- interpreting solutions as spatial maps and temporal traces of neural activity.

This is especially relevant for multimodal datasets where MEG/EEG and NIRS are analyzed jointly or separately.

### 3) Connectivity and dynamic measures

Once source time series are recovered, BEst can be used to evaluate patterns of temporal coordination and information flow. This allows the analysis of dynamic connectivity in source space, including how entropy-based metrics capture changes in coordinated brain activity over time.

## Typical workflow

A standard workflow is:

1. Import subject anatomy and functional recordings.
2. Build or load the forward model.
3. Define the inverse model and choose the entropy-based regularization.
4. Estimate source activity.
5. Inspect source maps and temporal signals.
6. Compute connectivity or entropy-based summaries.
7. Compare conditions or groups.

## Related documentation

- Brainstorm tutorial: [BEst](https://neuroimage.usc.edu/brainstorm/Tutorials/TutBEst)
- Brainstorm tutorial: [NIRSTORM – inverse problem using cMEM](https://neuroimage.usc.edu/brainstorm/Tutorials/NIRSTORM#Inverse_problem_using_cMEM)

## Notes

This plugin is intended for research use in Brainstorm and requires a proper Brainstorm installation, a valid anatomy model, and appropriate forward/inverse modeling assumptions for the dataset being analyzed.

For full methodological details, implementation choices, and step-by-step processing instructions, refer to the linked Brainstorm tutorials above.

[TUTORIAL](https://neuroimage.usc.edu/brainstorm/Tutorials/TutBEst)