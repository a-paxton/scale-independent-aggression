#### soa-libraries_and_functions.r: Part of `soa-interpersonal_level.Rmd` ####
#
# This script loads libraries and creates a number of 
# additional functions to facilitate data prep and analysis.
#
# The script `soa-required_packages.r` should be run once first
# to ensure that the all required packages have been installed.
#
# Written by: A. Paxton (University of Connecticut)
# Date last modified: 19 April 2019
#####################################################################################

#### Load necessary packages ####

# list of required packages
required_packages = c(
  'ggplot2',
  'dplyr'
)

# load required packages
invisible(lapply(required_packages, require, character.only = TRUE))

# "euclidean": get Euclidean distance in three-dimensional space
euclidean <- function(x,y,z) {
  seq.end = length(x)
  distance = sqrt((x[2:seq.end]-x[1:(seq.end-1)])^2 + 
                    (y[2:seq.end]-y[1:(seq.end-1)])^2 + 
                    (z[2:seq.end]-z[1:(seq.end-1)])^2)
  return(distance)
}
