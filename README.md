# IQUIZOO offline processing

## Introduction

Here are all the `MATLAB` codes used for calculating scores for the raw data from
the various assessment projects.

## Workflow

The function `wrapper` is the basic function used for the whole workflow. Basically
up to 3 levels of processing is supported.

* Call `Preproc` get variable `dataExtracted`
* Call `Proc` get variable `resdata`
* Call `Merges` get many resulting variables.
