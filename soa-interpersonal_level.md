---
title: 'Scales of Aggression: Data for Dyadic-Level Aggression'
output:
  html_document:
    keep_md: yes
    number_sections: yes
---

This R markdown provides the data preparation for the part our project analyzing the
fractal structure of body movement during conflict, as part of a larger project 
investigating the fractal structure of conflict from international to interpersonal
levels (Blau & Paxton, in press, *Complexity*). 

To run this from scratch, you will need the following files:

* `./data/raw_movement_data/prepped_data-DCC.csv`: File with raw movement data derived 
from head-mounted accelerometers. Data were originally collected as part of Paxton 
and Dale  (2017, *Frontiers in Psychology*). Data are freely available in the OSF 
repository for the original project (https://osf.io/x9ay6/) and linked in the OSF
repository for the current project (https://osf.io/8qcya/).
* `./scripts/soa-required_packages.r`: Installs required libraries, 
if they are not already installed. **NOTE**: This should be run *before* running 
this script.

The code will output time series of movement events taken from the continuous time
series in two ways:

* `threshold`: count an event as occurring if the change in Euclidean
  acceleration from sample to sample exceeds the 90th percentile in
  change-in-acceleration for that participant in that conversation
* `derivative`: count an event as occurring if we identify a switch point 
  in Euclidean jerk (the derivative of acceleration)

Although both analyses provide consistent patterns of results, we ultimately chose
to use the `threshold` data because it is more reflective of perceptible changes
in movement by their partners.

Data are saved in the `./data/movement_data/` directory, which is created along
the way. Output data are then used for the DFA analyses and in figure
generation by the `soa-code_data_figures.Rmd` file.

**Code written by**: A. Paxton (University of Connecticut)

**Date last modified**: 04 November 2020

***

# Preliminaries


```r
# clear things out
rm(list=ls())

# load in the required packages
source('./scripts/soa-libraries_and_functions.r')

# load in the data
movement_data = read.table('./data/raw_movement_data/prepped_data-DCC.csv',
                           sep=',', header=TRUE)
cutoff_data = read.table('./data/raw_movement_data/DCC-cutoff_jounce.csv',
                         sep=',', header=TRUE)
```

***

# Data preparation

First, we'll convert our raw *x,y,z* coordinates to Euclidean acceleration.


```r
# get Euclidean acceleration
movement_data = movement_data %>% ungroup() %>%
  group_by(dyad,partic,conv.num,conv.type,cond) %>%
  mutate(euclid_accel = c(NA,euclidean(x,y,z))) %>%
  select(-x, -y, -z) %>%
  dplyr::filter(!is.na(euclid_accel)) %>%
  mutate(euclid_accel = scale(euclid_accel))
```

Then, we'll trim the data to exclude the calibration and instruction times.


```r
# prepare to identify starting cutoff points
cutoff_points = cutoff_data %>% 
  rename(cutoff.t = t)

# implement cutoff based on movement 
movement_data = movement_data %>%  ungroup() %>%
  merge(., cutoff_points, 
        by = c('dyad','conv.num','conv.type','cond')) %>%
  group_by(dyad, conv.num, conv.type, cond) %>%
  dplyr::filter(t > unique(cutoff.t)) %>%
  select(-one_of('cutoff.t','cutoff'))
```

***

# Generating event time series

Here, let's generate the two candidate time series.

## Using 90th percentile movement threshold


```r
# identify events using thresholded Euclidean acceleration
threshold_timeseries = movement_data %>% ungroup() %>%
  group_by(partic, dyad, conv.num, conv.type, cond) %>%
  mutate(threshold = quantile(euclid_accel, .9)) %>%
  mutate(over_threshold = (euclid_accel > threshold)*1) %>%
  mutate(switch_point = over_threshold - lag(over_threshold, 
                                             default = first(over_threshold))) %>%
  dplyr::filter(switch_point==1)

# figure out how many events we've identified per participant
threshold_events = threshold_timeseries %>% ungroup() %>%
  group_by(partic, dyad, conv.num, conv.type, cond) %>%
  summarise(num_events = sum(over_threshold),
            threshold = unique(threshold))
```

```
## `summarise()` regrouping output by 'partic', 'dyad', 'conv.num', 'conv.type' (override with `.groups` argument)
```

```r
# print the minimum number of identified events per participant
min(threshold_events$num_events)
```

```
## [1] 1123
```

```r
# wipe out the unnecessary variables
threshold_timeseries = threshold_timeseries %>% ungroup() %>%
  select(-over_threshold, -switch_point)
```

## Using first derivative of Euclidean acceleration


```r
# identify events using the first derivative of the Euclidean acceleration
derivative_timeseries = movement_data %>% ungroup() %>%
  group_by(partic, dyad, conv.num, conv.type, cond) %>%
  mutate(jerk = c(0,diff(euclid_accel) / diff(t))) %>%
  mutate(over_threshold = (jerk > 0)*1) %>%
  mutate(switch_point = over_threshold - lag(over_threshold, 
                                             default = first(over_threshold))) %>%
  dplyr::filter(switch_point==1)

# figure out how many events we've identified per participant
derivative_events = derivative_timeseries %>% ungroup() %>%
  group_by(partic, dyad, conv.num, conv.type, cond) %>%
  summarise(num_events = sum(over_threshold))
```

```
## `summarise()` regrouping output by 'partic', 'dyad', 'conv.num', 'conv.type' (override with `.groups` argument)
```

```r
# print the minimum number of events identified per participants
min(derivative_events$num_events)
```

```
## [1] 10086
```

```r
# wipe out the unnecessary variables
derivative_timeseries = derivative_timeseries %>% ungroup() %>%
  select(-switch_point, -over_threshold)
```

***

# Export time series

Finally, we'll go ahead and save each individual's resulting event series
from each of the two techniques.


```r
# create the export directory if we don't have it yet
output_directory = file.path('./data/movement_data/')
dir.create(output_directory, 
           showWarnings = FALSE)
```



```r
# thanks to user Parfait (https://stackoverflow.com/a/50954201)
threshold_group_dfs = by(threshold_timeseries, 
                         threshold_timeseries[,c("partic", "dyad", "conv.type")], 
                         function(sub){
                           
                           # construct the file name
                           file_name <- paste("partic",
                                              max(as.character(sub$partic)), 
                                              "dyad",
                                              max(as.character(sub$dyad)),
                                              "type",
                                              max(as.character(sub$conv.type)), sep="_")
                           
                           # write each dataframe to a separate CSV
                           write.csv(sub, 
                                     paste0(output_directory, 
                                            "threshold-", file_name, ".csv"), 
                                     row.names = FALSE)
                           
                           # return each separate dataframe
                           return(sub)
                         })
```

## Export derivative-based event series


```r
# thanks to user Parfait (https://stackoverflow.com/a/50954201)
derivative_group_dfs = by(derivative_timeseries, 
                          derivative_timeseries[,c("partic", "dyad", "conv.type")], 
                          function(sub){
                            
                            # construct the file name
                            file_name <- paste("partic",
                                               max(as.character(sub$partic)), 
                                               "dyad",
                                               max(as.character(sub$dyad)),
                                               "type",
                                               max(as.character(sub$conv.type)), sep="_")
                            
                            # write each dataframe to a separate CSV
                            write.csv(sub, 
                                      paste0(output_directory,
                                             "derivative-", file_name, ".csv"), 
                                      row.names = FALSE)
                            
                            # return each separate dataframe
                            return(sub)
                          })
```
