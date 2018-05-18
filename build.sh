#!/bin/bash
set -x
set -e

CM_EXT_BRANCH=cm5-5.12.0

ANACONDA_URL=https://repo.anaconda.com/archive/Anaconda3-5.1.0-Linux-x86_64.sh
ANACONDA_MD5="966406059cf7ed89cc82eb475ba506e5" # from https://docs.anaconda.com/anaconda/install/hashes/Anaconda3-5.1.0-Linux-x86_64.sh-hash
ANACONDA_VERSION=5.1.0

AIRFLOW_VERSION=1.9.0


anaconda_installer="$( basename $ANACONDA_URL )"
anaconda_prefix="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
anaconda_folder="Anaconda3-${ANACONDA_VERSION}"


airflow_parcel_folder="AIRFLOW-${AIRFLOW_VERSION}"
airflow_parcel_name="${airflow_parcel_folder}-el7.parcel"
airflow_built_folder="${airflow_parcel_folder}_build"

function build_cm_ext {

  #Checkout if dir does not exist
  if [ ! -d cm_ext ]; then
    git clone https://github.com/cloudera/cm_ext.git
  fi
  if [ ! -f cm_ext/validator/target/validator.jar ]; then
    cd cm_ext
    git checkout "$CM_EXT_BRANCH"
    mvn install
    cd ..
  fi
}

function get_anaconda_with_airflow {
  if [ ! -f "$anaconda_installer" ]; then
    echo " -- Downloading Anaconda3 distribution"
    wget $ANACONDA_URL
  fi

  echo " -- Checking Anaconda3 distribution's hash"
  anaconda_md5="$( md5sum $anaconda_installer | cut -d' ' -f1 )"
  if [ "$anaconda_md5" != "$ANACONDA_MD5" ]; then
    echo ERROR: md5 of $anaconda_installer is not correct
    exit 1
  fi
  if [ ! -d "$anaconda_folder" ]; then
    echo " -- Installing Anaconda3"
    bash $anaconda_installer -b -p "$anaconda_prefix/$anaconda_folder"  # -b means silent mode; -p means prefix,ie path to installation directory
  fi
  
  echo " -- Installing python packages"
  PATH=$anaconda_prefix/$anaconda_folder/bin:$PATH
  pip install apache-airflow[all]=="$AIRFLOW_VERSION"
  pip install kerberos
  pip install hdfs
  pip install celery[redis]==3.1.17
  pip install flower
  pip install flask-bcrypt
  /usr/bin/yes | pip uninstall snakebite

  echo " -- Clearing installed python executables"  
  set +e
  sed -i -- 's|#!'"$anaconda_prefix/$anaconda_folder"'/bin/python|#!/usr/bin/env python|g' "$anaconda_prefix"/"$anaconda_folder"/bin/*
  set -e

}

function build_parcel {
  if [ -f "$airflow_built_folder/$airflow_parcel_name" ] && [ -f "$airflow_built_folder/manifest.json" ]; then
    return
  fi
  if [ ! -d $airflow_parcel_folder ]; then
    get_anaconda_with_airflow
    mv $anaconda_folder $airflow_parcel_folder
  fi

  echo " -- Creating parcel metadata"
  cp -r airflow-parcel-src/meta $airflow_parcel_folder
  sed -i -e "s/%AIRFLOW_VERSION%/$AIRFLOW_VERSION/" ./$airflow_parcel_folder/meta/parcel.json
  sed -i -e "s/%ANACONDA_VERSION%/$ANACONDA_VERSION/" ./$airflow_parcel_folder/meta/parcel.json

  echo " -- Validating parcel folder"
  java -jar cm_ext/validator/target/validator.jar -d ./$airflow_parcel_folder

  echo " -- Creating parcel archive"
  mkdir -p $airflow_built_folder

  set +e #prevent breaks by tar warnings
  tar zcvhf ./$airflow_built_folder/$airflow_parcel_name $airflow_parcel_folder --owner=root --group=root
  set -e

  echo " -- Validating parcel archive"
  java -jar cm_ext/validator/target/validator.jar -f ./$airflow_built_folder/$airflow_parcel_name

  echo " -- Creating manifest"
  python cm_ext/make_manifest/make_manifest.py ./$airflow_built_folder
}

function build_csd {
  JARNAME=AIRFLOW-${AIRFLOW_VERSION}.jar
  if [ -f "$JARNAME" ]; then
    return
  fi
  java -jar cm_ext/validator/target/validator.jar -s ./airflow-csd-src/descriptor/service.sdl

  jar -cvf ./$JARNAME -C ./airflow-csd-src .
}


case $1 in
clean)
  if [ -d cm_ext ]; then
    rm -rf cm_ext
  fi
  if [ -d "$anaconda_folder" ]; then
    rm -rf "$anaconda_folder"
  fi
  if [ -d "$airflow_parcel_folder" ]; then
    rm -rf "$airflow_parcel_folder"
  fi
  if [ -d "$airflow_built_folder" ]; then
    rm -rf "$airflow_built_folder"
  fi
  ;;
parcel)
  build_cm_ext
  build_parcel
  ;;
csd)
  build_csd
  ;;
*)
  echo "Usage: $0 [parcel|csd|clean]"
  ;;
esac
