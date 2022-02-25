# MATESSE Channel Card project repository

## Introduction

This repository does not track the Vivado project itself, instead contains all the source files and scripts needed to generate the vivado project.

## How to generate the vivado project

1. Change the route to your vivado executable in the *build.bat* file
```
C:/<YOUR PATH>/vivado.bat -mode batch -source project_script.tcl
```
2. Execute the *build.bat* file
3. A Vivado project should have been created in ./project/ folder. Open the .xpr with Vivado 2019.1

## Requirements

- Xilinx Vivado 2019.1