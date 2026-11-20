
set(CMAKE_INCLUDE_CURRENT_DIR ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

if(APPLE)
	enable_language(OBJCXX)
endif()

find_package(Qt6 REQUIRED COMPONENTS Core Gui Concurrent Svg Qml Quick Widgets)
if(Qt6_VERSION VERSION_GREATER_EQUAL "6.10.0")
	find_package(Qt6 REQUIRED COMPONENTS GuiPrivate)
endif()

find_package(Qt6 COMPONENTS WebEngineQuick)
find_package(Qt6 COMPONENTS DBus)

if(WIN32)
	add_definitions(-DWIN32_LEAN_AND_MEAN)
endif()

set(SOURCE_FILES
	include/exception.h
	src/main.cpp
	include/discoverymanager.h
	src/discoverymanager.cpp
	include/streamsession.h
	src/streamsession.cpp
	include/sessionlog.h
	src/sessionlog.cpp
	include/settings.h
	src/settings.cpp
	include/host.h
	src/host.cpp
	res/resources.qrc
	include/controllermanager.h
	src/controllermanager.cpp
	include/psnaccountid.h
	src/psnaccountid.cpp
	include/psntoken.h
	src/psntoken.cpp
	include/jsonrequester.h
	src/jsonrequester.cpp
	src/qml/qml.qrc
	include/qmlmainwindow.h
	src/qmlmainwindow.cpp
	include/qmlbackend.h
	src/qmlbackend.cpp
	include/qmlcontroller.h
	src/qmlcontroller.cpp
	include/qmlsettings.h
	src/qmlsettings.cpp
	include/qmlsvgprovider.h
	src/qmlsvgprovider.cpp
	include/systemdinhibit.h
	src/systemdinhibit.cpp
	)
# vice hook: our QML, selected over upstream screens at runtime (see qmlmainwindow.cpp)
if(CHIAKI_ENABLE_VICE_UI)
	if(Qt6_VERSION VERSION_LESS "6.6.0")
		message(FATAL_ERROR "The Vice UI needs Qt 6.6 or newer (found ${Qt6_VERSION}). Use a newer Qt, or configure with -DCHIAKI_ENABLE_VICE_UI=OFF.")
	endif()
	find_package(Qt6 REQUIRED COMPONENTS Network)
	list(APPEND SOURCE_FILES
		src/qml/vice.qrc
		include/vice/netcheck.h
		src/vice/netcheck.cpp
		include/vice/brand.h
		src/vice/brand.cpp
		include/vice/platform.h
		src/vice/platform.cpp
		include/vice/engine.h
		src/vice/engine.cpp
		src/vice/engine_platform.cpp
		src/vice/rtxvideo.cpp)
	if(APPLE)
		list(APPEND SOURCE_FILES src/vice/wifi_mac.mm)
	endif()
	add_definitions(-DCHIAKI_VICE_UI)
	# Background artwork has its own terms, apart from the source code (see src/qml/vice/artwork/SOURCE.md)
	set(VICE_ARTWORK "${CMAKE_CURRENT_SOURCE_DIR}/src/qml/vice/artwork/key-art.jpg")
	if(EXISTS "${VICE_ARTWORK}")
		file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/vice-artwork.qrc"
			"<RCC><qresource prefix=\"/vice/artwork\"><file alias=\"key-art.jpg\">${VICE_ARTWORK}</file></qresource></RCC>\n")
		list(APPEND SOURCE_FILES "${CMAKE_CURRENT_BINARY_DIR}/vice-artwork.qrc")
		message(STATUS "Vice UI: bundling artwork")
	else()
		message(STATUS "Vice UI: no artwork file, screens use the plain background")
	endif()
endif()
set(RESOURCE_FILES "")

if(APPLE)
	list(APPEND RESOURCE_FILES "chiaking.icns")
elseif(WIN32)
	configure_file(
		${CMAKE_CURRENT_SOURCE_DIR}/chiaking.rc.in
		${CMAKE_CURRENT_SOURCE_DIR}/chiaking.rc
		@ONLY)
	list(APPEND RESOURCE_FILES "chiaking.rc")
endif()

# vice hook: the Project Vice icon in place of upstream's (design/icons/03-sunset-wordmark.png)
if(CHIAKI_ENABLE_VICE_UI)
	if(APPLE)
		set(RESOURCE_FILES "vice.icns")
	elseif(WIN32)
		file(READ "${CMAKE_CURRENT_SOURCE_DIR}/chiaking.rc" VICE_RC)
		string(REPLACE "chiaking.ico" "vice.ico" VICE_RC "${VICE_RC}")
		# The product's name in the file properties; the copyright line is left as it is
		string(REPLACE "\"next-generation of Chiaki\"" "\"Project Vice\"" VICE_RC "${VICE_RC}")
		string(REPLACE "\"InternalName\", \"chiaki-ng\"" "\"InternalName\", \"Project Vice\"" VICE_RC "${VICE_RC}")
		string(REPLACE "\"ProductName\", \"chiaki-ng\"" "\"ProductName\", \"Project Vice\"" VICE_RC "${VICE_RC}")
		string(REPLACE "\"chiaki.exe\"" "\"ProjectVice.exe\"" VICE_RC "${VICE_RC}")
		file(WRITE "${CMAKE_CURRENT_SOURCE_DIR}/chiaking.rc" "${VICE_RC}")
	endif()
endif()

if(CHIAKI_ENABLE_STEAMDECK_NATIVE AND LINUX)
	list(APPEND SOURCE_FILES
		include/sdinputcontext.h
		src/sdinputcontext.cpp
	)
endif()

if(APPLE)
	list(APPEND SOURCE_FILES
		include/macMicPermission.h
		src/macMicPermission.m
		include/macWakeSleep.h
		src/macWakeSleep.cpp
	)
elseif(WIN32)
	list(APPEND SOURCE_FILES
		include/windowsWakeSleep.h
		src/windowsWakeSleep.cpp
	)
endif()

add_executable(chiaki WIN32
		${RESOURCE_FILES}
		${SOURCE_FILES}
)
target_include_directories(chiaki PRIVATE include)

add_library(placebo-libav-impl src/libav_impl.c)
target_link_libraries(placebo-libav-impl PkgConfig::LIBPLACEBO FFMPEG::avcodec FFMPEG::avutil FFMPEG::avformat)
target_link_libraries(chiaki PkgConfig::LIBPLACEBO placebo-libav-impl)

target_link_libraries(chiaki chiaki-lib)
if(CHIAKI_ENABLE_CLI)
	add_definitions(-DCHIAKI_ENABLE_CLI)
	target_link_libraries(chiaki chiaki-cli-lib)
endif()

target_link_libraries(chiaki Qt::Core Qt::Gui Qt::GuiPrivate Qt::Concurrent Qt::Svg Qt::Qml Qt::Quick Qt::Widgets)
if (${Qt6DBus_FOUND} AND NOT WIN32)
	target_link_libraries(chiaki Qt::DBus)
if (NOT APPLE)
	target_compile_definitions(chiaki PRIVATE CHIAKI_HAVE_DBUS)
endif()
endif()
if (${Qt6WebEngineQuick_FOUND})
	target_link_libraries(chiaki Qt::WebEngineQuick)
	target_compile_definitions(chiaki PRIVATE CHIAKI_HAVE_WEBENGINE)
endif()
target_link_libraries(chiaki SDL2::SDL2)
if(CHIAKI_ENABLE_SPEEX)
  target_link_libraries(chiaki PkgConfig::SpeexDSP)
  target_compile_definitions(chiaki PRIVATE CHIAKI_GUI_ENABLE_SPEEX)
endif()
if(CHIAKI_GUI_ENABLE_SDL_GAMECONTROLLER)
	target_compile_definitions(chiaki PRIVATE CHIAKI_GUI_ENABLE_SDL_GAMECONTROLLER)
endif()
if(CHIAKI_ENABLE_SETSU)
	target_link_libraries(chiaki setsu)
	target_compile_definitions(chiaki PRIVATE CHIAKI_GUI_ENABLE_SETSU)
endif()
if(CHIAKI_ENABLE_STEAMDECK_NATIVE)
	target_link_libraries(chiaki sdeck)
	target_compile_definitions(chiaki PRIVATE QT_STATICPLUGIN CHIAKI_GUI_ENABLE_STEAMDECK_NATIVE)
endif()
if(CHIAKI_ENABLE_STEAM_SHORTCUT)
	target_link_libraries(chiaki cpp-steam-tools)
	target_compile_definitions(chiaki PRIVATE CHIAKI_GUI_ENABLE_STEAM_SHORTCUT)
endif()
if(NOT CHIAKI_ENABLE_FFMPEG_DECODER)
	message(FATAL_ERROR "Chiaki GUI requires CHIAKI_ENABLE_FFMPEG_DECODER=ON")
endif()
if(APPLE)
	target_link_libraries(chiaki "-framework AVFoundation" "-framework IOKit")
endif()

# set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fanalyzer")
set_target_properties(chiaki PROPERTIES
		MACOSX_BUNDLE TRUE
		MACOSX_BUNDLE_INFO_PLIST "${CMAKE_CURRENT_SOURCE_DIR}/MacOSXBundleInfo.plist.in"
		MACOSX_BUNDLE_BUNDLE_NAME chiaki-ng
		MACOSX_BUNDLE_BUNDLE_VERSION ${CHIAKI_VERSION}
		MACOSX_BUNDLE_COPYRIGHT "thestr4ng3r (AGPLv3)"
		MACOSX_BUNDLE_GUI_IDENTIFIER "org.streetpea.chiaking"
		MACOSX_BUNDLE_ICON_FILE chiaking.icns
		RESOURCE "${RESOURCE_FILES}")

# vice hook: name shown in the macOS menu bar, and the network check's Qt module
if(CHIAKI_ENABLE_VICE_UI)
	target_link_libraries(chiaki Qt::Network FFMPEG::avformat FFMPEG::avcodec FFMPEG::avutil)
	if(APPLE)
		target_link_libraries(chiaki "-framework CoreWLAN")
		# Qt opens the Vulkan loader by name and only finds one inside a deployed bundle.
		# A build run from the build tree is told where this machine's loader is (see main.cpp).
		find_library(VICE_VULKAN_LOADER NAMES vulkan vulkan.1 HINTS /opt/homebrew/lib /usr/local/lib)
		if(VICE_VULKAN_LOADER)
			target_compile_definitions(chiaki PRIVATE VICE_VULKAN_LOADER="${VICE_VULKAN_LOADER}")
		endif()
		# MoltenVK goes inside the app, where the Vulkan loader looks first, so the app
		# has its Vulkan driver on any Mac without anything being installed or configured.
		find_library(VICE_MOLTENVK NAMES MoltenVK HINTS /opt/homebrew/lib /usr/local/lib)
		if(VICE_MOLTENVK)
			set(VICE_ICD_DIR "$<TARGET_BUNDLE_CONTENT_DIR:chiaki>/Resources/vulkan/icd.d")
			file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/MoltenVK_icd.json"
				"{\"file_format_version\": \"1.0.0\", \"ICD\": {\"library_path\": \"./libMoltenVK.dylib\", \"api_version\": \"1.2.0\", \"is_portability_driver\": true}}\n")
			add_custom_command(TARGET chiaki POST_BUILD
				COMMAND ${CMAKE_COMMAND} -E make_directory "${VICE_ICD_DIR}"
				COMMAND ${CMAKE_COMMAND} -E copy "${VICE_MOLTENVK}" "${VICE_ICD_DIR}/libMoltenVK.dylib"
				COMMAND ${CMAKE_COMMAND} -E copy "${CMAKE_CURRENT_BINARY_DIR}/MoltenVK_icd.json" "${VICE_ICD_DIR}/MoltenVK_icd.json")
		else()
			message(WARNING "MoltenVK not found: on macOS the app will fall back to OpenGL, which is slower and less even. brew install molten-vk")
		endif()
	elseif(WIN32)
		target_link_libraries(chiaki winmm wlanapi avrt qwave ws2_32 setupapi dxgi dxguid)
	endif()
	set_target_properties(chiaki PROPERTIES
		MACOSX_BUNDLE_BUNDLE_NAME "Project Vice"
		MACOSX_BUNDLE_GUI_IDENTIFIER "app.projectvice.ProjectVice"
		MACOSX_BUNDLE_INFO_PLIST "${CMAKE_CURRENT_SOURCE_DIR}/MacOSXBundleInfo.vice.plist.in"
		MACOSX_BUNDLE_ICON_FILE vice.icns)
	# The program and app bundle carry the product's name. The CMake target stays "chiaki".
	if(APPLE)
		set_target_properties(chiaki PROPERTIES OUTPUT_NAME "Project Vice")
	elseif(WIN32)
		set_target_properties(chiaki PROPERTIES OUTPUT_NAME "ProjectVice")
	else()
		set_target_properties(chiaki PROPERTIES OUTPUT_NAME "project-vice")
	endif()
endif()

install(TARGETS chiaki
		RUNTIME DESTINATION bin
		BUNDLE DESTINATION bin)
if(NOT CHIAKI_ENABLE_VICE_UI) # vice hook: the product installs its own desktop entry and icon instead
install(FILES chiaking.desktop DESTINATION share/applications)
install(FILES chiaking.png DESTINATION share/icons/hicolor/512x512/apps)
endif()
if(CHIAKI_ENABLE_VICE_UI)
	# vice hook
	install(FILES vice.png DESTINATION share/icons/hicolor/512x512/apps RENAME project-vice.png)
	install(FILES project-vice.desktop DESTINATION share/applications)
endif()
if(NOT CHIAKI_ENABLE_VICE_UI) # vice hook
install(FILES io.github.streetpea.Chiaki4deck.appdata.xml DESTINATION share/metainfo)
endif()
