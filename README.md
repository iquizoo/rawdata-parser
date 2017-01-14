# Explanation

**CCDPro** is abbreviation of _Children Cognitive Development Project_. This project
is supported by Chinese government, which is part of _Beijing Brain Project_.

The scripts here are currently mainly for the behavior data collected from
Chongqing, and Beijing. The goal here is just to develop **easy-to-use** scripts
implemented in `MATLAB`, Mathworks.

# Workflow

The function `wrapper` is the basic function used for the whole workflow. Basically
up to 3 levels of processing is supported.

* Call `Preproc` get variable `dataExtracted`
* Call `Proc` get variable `resdata`
* Call `Merges` get many resulting variables.
