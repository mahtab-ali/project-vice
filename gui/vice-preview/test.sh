#!/bin/sh
# Runs the Vice behaviour tests. Needs qmltestrunner from Qt.
cd "$(dirname "$0")" || exit 1
QT_QUICK_CONTROLS_STYLE=Basic qmltestrunner -input tests "$@"
