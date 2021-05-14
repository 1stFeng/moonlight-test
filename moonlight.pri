!isEmpty(MOONLIGHT_PRI_INCLUDED):error("moonlight.pri already included")
MOONLIGHT_PRI_INCLUDED = 1

MOONLIGHT_VERSION = 1.1.1
MOONLIGHT_COMPAT_VERSION = 1.1.1
#VERSION = $$MOONLIGHT_VERSION
MOONLIGHT_DISPLAY_VERSION = 1.1.1

defineReplace(cleanPath) {
    return($$clean_path($$1))
}

CONFIG += c++14

defineReplace(qtLibraryName) {
   unset(LIBRARY_NAME)
   LIBRARY_NAME = $$1
   CONFIG(debug, debug|release) { 
      !debug_and_release|build_pass {
          mac:RET = $$member(LIBRARY_NAME, 0)_debug
              win32:RET = $$member(LIBRARY_NAME, 0)d
              linux:RET = $$member(LIBRARY_NAME, 0)

      }
   }
   isEmpty(RET):RET = $$LIBRARY_NAME
   return($$RET)
}

isEmpty(IDE_LIBRARY_BASENAME) {
    IDE_LIBRARY_BASENAME = libs
}

IDE_ROOT_PATH = $$PWD
IDE_SOURCE_TREE = $$IDE_ROOT_PATH/source
IDE_BUILD_TREE = $$IDE_ROOT_PATH/build
IDE_BIN=bin
CONFIG(debug, debug|release) {
    IDE_BIN=bin_debug
}
CONFIG(release, debug|release) {
    IDE_BIN=bin
}

osx{
    IDE_APP_TARGET          = MoonLight
    IDE_APP_PATH            = $$IDE_ROOT_PATH/$$IDE_BIN/app
    IDE_PLUGIN_PATH         = $$IDE_ROOT_PATH/$$IDE_BIN/plugins
    IDE_DEPNDSLIB_PATH      = $$IDE_ROOT_PATH/$$IDE_BIN/libs
    IDE_LIBRARY_PATH        = $$IDE_ROOT_PATH/$$IDE_BIN/libs
    IDE_BIN_PATH            = $$IDE_ROOT_PATH/$$IDE_BIN
}else {
    IDE_APP_TARGET          = MoonLight
    IDE_APP_PATH            = $$IDE_ROOT_PATH/$$IDE_BIN/app
    isEmpty(IDE_OUTPUT_PATH): IDE_OUTPUT_PATH = $$IDE_BUILD_TREE
    IDE_PLUGIN_PATH         = $$IDE_ROOT_PATH/$$IDE_BIN/plugins
    IDE_DEPNDSLIB_PATH      = $$IDE_BUILD_TREE/lib
    IDE_LIBRARY_PATH        = $$IDE_ROOT_PATH/$$IDE_BIN/libs
    IDE_BIN_PATH            = $$IDE_ROOT_PATH/$$IDE_BIN
    IDE_DATA_PATH           = $$IDE_BIN_PATH/share/moonlight
    IDE_DOC_PATH            = $$IDE_BIN_PATH/share/doc/moonlight
}

RELATIVE_PLUGIN_PATH = $$relative_path($$IDE_PLUGIN_PATH, $$IDE_APP_PATH)
RELATIVE_LIBEXEC_PATH = $$relative_path($$IDE_LIBEXEC_PATH, $$IDE_APP_PATH)
RELATIVE_DATA_PATH = $$relative_path($$IDE_DATA_PATH, $$IDE_APP_PATH)
RELATIVE_DOC_PATH = $$relative_path($$IDE_DOC_PATH, $$IDE_APP_PATH)
DEFINES += $$shell_quote(RELATIVE_PLUGIN_PATH=\"$$RELATIVE_PLUGIN_PATH\")
DEFINES += $$shell_quote(RELATIVE_LIBEXEC_PATH=\"$$RELATIVE_LIBEXEC_PATH\")
DEFINES += $$shell_quote(RELATIVE_DATA_PATH=\"$$RELATIVE_DATA_PATH\")
DEFINES += $$shell_quote(RELATIVE_DOC_PATH=\"$$RELATIVE_DOC_PATH\")

CONFIG(debug, debug|release) {
    MOC_DIR += $$IDE_BUILD_TREE/moc/debug/$$TARGET
    RCC_DIR += $$IDE_BUILD_TREE/rcc/debug/$$TARGET
    UI_DIR += $$IDE_BUILD_TREE/ui/debug/$$TARGET
    OBJECTS_DIR += $$IDE_BUILD_TREE/obj/debug/$$TARGET
}
else{
    MOC_DIR += $$IDE_BUILD_TREE/moc/release/$$TARGET
    RCC_DIR += $$IDE_BUILD_TREE/rcc/release/$$TARGET
    UI_DIR += $$IDE_BUILD_TREE/ui/release/$$TARGET
    OBJECTS_DIR += $$IDE_BUILD_TREE/obj/release/$$TARGET
}

qt {
    contains(QT, core): QT += concurrent
    contains(QT, gui): QT += widgets
}

win32-msvc*{
    DEFINES += _UNICODE
    QMAKE_LFLAGS += /INCREMENTAL:NO\
        /IMPLIB:$$IDE_BUILD_TREE/lib/$$qtLibraryName($$TARGET).lib\
        /PDB:$$IDE_BUILD_TREE/symbols/$$qtLibraryName($$TARGET).pdb
    QMAKE_CXXFLAGS_RELEASE += /Zi /Od
    QMAKE_LFLAGS_RELEASE += /DEBUG
}
linux-g++{
    CONFIG(debug, debug|release) {
        DEFINES += _DEBUG
    }

    QMAKE_CXXFLAGS_WARN_ON +=   \
                        -Wno-unused-function \
                        -Wno-unused-parameter \
                        -Wno-unused-variable \
                        -Wno-switch \
                        -Wno-comment \
                        -Wno-unused-but-set-variable
}

INCLUDEPATH += \
    $$IDE_SOURCE_TREE/ \
    $$IDE_SOURCE_TREE/libs \
    $$IDE_SOURCE_TREE/app

QTC_PLUGIN_DIRS_FROM_ENVIRONMENT = $$(QTC_PLUGIN_DIRS)
QTC_PLUGIN_DIRS += $$split(QTC_PLUGIN_DIRS_FROM_ENVIRONMENT, $$QMAKE_DIRLIST_SEP)
QTC_PLUGIN_DIRS += $$IDE_SOURCE_TREE/plugins
for(dir, QTC_PLUGIN_DIRS) {
    INCLUDEPATH += $$dir
}

DESTDIR = $$IDE_PLUGIN_PATH/$$DESTDIR
LIBS = -L$$IDE_DEPNDSLIB_PATH
DEFINES += XPLUGIN_EXPORTS
DEFINES += IDE_ROOT_PATH=\\\"$$IDE_ROOT_PATH\\\"

!isEmpty(QTC_PLUGIN_DEPENDS) {
    LIBS *= -L$$IDE_PLUGIN_PATH  # plugin path from output directory
}
# recursively resolve plugin deps
done_plugins =
for(ever) {
    isEmpty(QTC_PLUGIN_DEPENDS): \
        break()
    done_plugins += $$QTC_PLUGIN_DEPENDS
    for(dep, QTC_PLUGIN_DEPENDS) {
        dependencies_file =
        for(dir, QTC_PLUGIN_DIRS) {
            exists($$dir/$$dep/$${dep}_dependencies.pri) {
                dependencies_file = $$dir/$$dep/$${dep}_dependencies.pri
                break()
            }
        }
        isEmpty(dependencies_file): \
            error("Plugin dependency $$dep not found")
        include($$dependencies_file)
        LIBS += -l$$qtLibraryName($$QTC_PLUGIN_NAME)
    }
    QTC_PLUGIN_DEPENDS = $$unique(QTC_PLUGIN_DEPENDS)
    QTC_PLUGIN_DEPENDS -= $$unique(done_plugins)
}

# recursively resolve library deps
done_libs =
for(ever) {
    isEmpty(QTC_LIB_DEPENDS): \
        break()
    done_libs += $$QTC_LIB_DEPENDS
    for(dep, QTC_LIB_DEPENDS) {
        include($$PWD/source/libs/$$dep/$${dep}_dependencies.pri)
        LIBS += -l$$qtLibraryName($$QTC_LIB_NAME)
    }
    QTC_LIB_DEPENDS = $$unique(QTC_LIB_DEPENDS)
    QTC_LIB_DEPENDS -= $$unique(done_libs)
}
