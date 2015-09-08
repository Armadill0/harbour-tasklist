#!/bin/bash

APP_NAME=$(pwd | awk -F'/' '{print $NF}')
QM_TARGET=localization
TS_SOURCES=localization-sources

echo "Running TS generator for app '${APP_NAME}'"

echo "Updating ts files..."
lupdate ${APP_NAME}.pro -ts ${TS_SOURCES}/*.ts
