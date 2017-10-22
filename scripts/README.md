# Analysis functions

Here contains all the analysis functions, whose names all begin with a string 'sngproc'.

## Specifications

### Reaction-time outliers

#### For tasks that *Reaction Time* is an indicator of interest

Based on [this post](http://condor.depaul.edu/dallbrit/extra/resources/ReactionTimeData-2017-4-4.html), if *reaction time* is an indicator of interest, which means that users' **speed** is so important that reaction time is a crucial indicator of users' performance on one task, we adopt a two-step protocol to do outlier detection for reaction times, and implement it in the function [`rmoutlier`](rmoutlier.m). Specifically, the two steps are

1. Treat all the reaction times faster than 100 ms as outliers.
1. Using a [Tukey boxplot method](https://en.wikipedia.org/wiki/Box_plot) to detect reactions-time outliers that are still too slow or too fast.

For those tasks with multiple conditions, such as 'Flanker test', we do outlier detection on each condition, in consideration of the heterogeneous of the distribution of different conditions.

Detected outliers are so deemed as invalid measurements, or invalid responses of users, that we just remove them in further analysis, including proportion of error/correct calculation. That is, if one reaction time is treated as outlier, it is simply dropped from data.

#### For tasks that *Accuracy* is an indicator of interest

When we care about the users' *accuracy* is an indicator of interest, which means that users' **speed** is less important, we adopt only a cutoff to reaction times. That is, we only treat those reaction times that are faster than 100 ms as outliers.

Just as in the previous section, all the detected outliers are simply dropped from data, for we do not know the real answer would be if the reaction time for that trial were right.
