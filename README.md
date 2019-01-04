# Apache Airflow parcel and CSD for Cloudera

This git repository is used to build both CSDs and parcels for CDH.

Airflow will run as service in Cloudera Manager, and its configuration is maintained through the CM web UI.
All necessary python packeges (airflow, celery, flower, flask) are installed inside the parcel which uses Anaconda3 distribution.

There are used Anaconda3 v5.1.0 and Airflow v1.10.1

This has been tested on CDH 5.14.0.

## Prerequisites

```bash

sudo apt install maven
sudo apt-get install libmysqlclient-dev
sudo apt-get install libkrb5-dev
```

## Build

To build the CSDs and Parcels yourself, you can run the build script:

```
#Installation and upgrading requires setting SLUGIFY_USES_TEXT_UNIDECODE=yes
export SLUGIFY_USES_TEXT_UNIDECODE=yes
#Build the Parcel files, this make take some time
sh build.sh parcel

#Build the CSDs
sh build.sh csd
```

## Installation

Information about installing custom services can be found at [https://www.cloudera.com/documentation/enterprise/latest/topics/cm_mc_addon_services.html](https://www.cloudera.com/documentation/enterprise/latest/topics/cm_mc_addon_services.html).

## Configuration

TODO
