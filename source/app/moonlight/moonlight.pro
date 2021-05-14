DESTDIR = app
include(../../../moonlight.pri)
include(main.pri)

QT       += core gui

TEMPLATE = app
CONFIG += qtc_runnable
TARGET = $$IDE_APP_TARGET
DESTDIR = $$IDE_APP_PATH
VERSION = $$QTCREATOR_VERSION
QT -= testlib

include(../../../source/rpath.pri)
LIBS *= -l$$qtLibraryName(ExtensionSystem) -l$$qtLibraryName(Aggregation) -l$$qtLibraryName(Utils)
