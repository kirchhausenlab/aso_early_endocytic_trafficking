# aso_early_endocytic_trafficking

Code associated with:

Sitarska E, Saminathan A, Scanavachi G, Somerville E, Stock P, Shen P, Kahne D, Courtney MF, Reid DA, Danielsen M, Davidsen F, Jensen K, Bennett CF, Kirchhausen T (2026) Naked antisense oligonucleotides access the cytosol during early endocytic trafficking. Nucleic Acids Research.

## Overview

This repository contains Fiji/ImageJ macros for multichannel image registration and 3D quantification of fluorescence intensity and ratiometric measurements within endosomes.

## Included scripts

### register_multichannel_stacks.ijm
Performs affine registration of fluorescence channels in three-channel 3D image stacks using MultiStackReg.

### quantify_endosomal_fluorescence_3d.ijm
Identifies individual 3D endosomal objects from a binary primary-channel mask and quantifies object volume, fluorescence intensity in two channels, and mask overlap, providing measurements for downstream ratiometric analysis.

## Requirements

Fiji/ImageJ with:
- MultiStackReg plugin
- 3D ImageJ Suite / 3D Manager
