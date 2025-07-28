cmake_minimum_required(VERSION 3.18)

# Project configuration
if(NOT DEFINED PROJECT_VERSION)
    set(PROJECT_VERSION "1.0.0")
endif()

project(mmap2 
    VERSION ${PROJECT_VERSION}
    DESCRIPTION "Cross-platform C wrapper for mio memory mapping library"
    LANGUAGES CXX
)

# Modern CMake settings
set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Build type configuration
if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
    set(CMAKE_BUILD_TYPE Release CACHE STRING "Choose the type of build" FORCE)
    set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS "Debug" "Release" "MinSizeRel" "RelWithDebInfo")
endif()

# Platform detection and configuration
set(IS_ANDROID FALSE)
set(IS_IOS FALSE)
set(IS_MACOS FALSE)
set(IS_WINDOWS FALSE)
set(IS_LINUX FALSE)

if(ANDROID)
    set(IS_ANDROID TRUE)
    message(STATUS "Building for Android - ABI: ${ANDROID_ABI}")
elseif(CMAKE_SYSTEM_NAME MATCHES "iOS|watchOS|tvOS|visionOS")
    set(IS_IOS TRUE)
    message(STATUS "Building for iOS/Apple platforms - Platform: ${PLATFORM}")
elseif(APPLE)
    set(IS_MACOS TRUE)
    message(STATUS "Building for macOS")
elseif(WIN32)
    set(IS_WINDOWS TRUE)
    message(STATUS "Building for Windows")
elseif(UNIX)
    set(IS_LINUX TRUE)
    message(STATUS "Building for Linux")
endif()

# Source files
set(SOURCES
    src/mio_wrapper.cpp
)

set(HEADERS
    include/mio_wrapper.h
)

# Create the target - static for iOS only, shared for others
if(IS_IOS)
    add_library(${PROJECT_NAME} STATIC ${SOURCES} ${HEADERS})
    message(STATUS "Creating static library for iOS platform")
else()
    add_library(${PROJECT_NAME} SHARED ${SOURCES} ${HEADERS})
    message(STATUS "Creating shared library for ${CMAKE_SYSTEM_NAME}")
    
    # Define symbol export macro for shared libraries
    target_compile_definitions(${PROJECT_NAME} PRIVATE MIO_WRAPPER_BUILDING_DLL)
endif()

# Add an alias for modern CMake usage
add_library(mmap2::mmap2 ALIAS ${PROJECT_NAME})

# Target properties
set_target_properties(${PROJECT_NAME} PROPERTIES
    PUBLIC_HEADER "${HEADERS}"
    POSITION_INDEPENDENT_CODE ON
)

# Include directories using modern CMake
target_include_directories(${PROJECT_NAME}
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
        $<INSTALL_INTERFACE:include>
    PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/../mio/single_include
)

# Compiler-specific settings
target_compile_options(${PROJECT_NAME} PRIVATE
    $<$<CXX_COMPILER_ID:MSVC>:/W4>
    $<$<CXX_COMPILER_ID:GNU>:-Wall -Wextra -Wpedantic>
    $<$<CXX_COMPILER_ID:Clang>:-Wall -Wextra -Wpedantic>
)

# Platform-specific configurations
if(IS_ANDROID)
    # Android-specific settings
    target_compile_definitions(${PROJECT_NAME} PRIVATE ANDROID_PLATFORM)
    
    # Debug-specific settings for Android
    target_compile_options(${PROJECT_NAME} PRIVATE
        $<$<CONFIG:Debug>:-g -O0 -fno-omit-frame-pointer>
    )
    
    # Release-specific optimizations for Android
    target_compile_options(${PROJECT_NAME} PRIVATE
        $<$<CONFIG:Release>:-O3 -DNDEBUG -ffunction-sections -fdata-sections -fvisibility=hidden>
    )
    
    target_link_options(${PROJECT_NAME} PRIVATE
        $<$<CONFIG:Release>:-Wl,--gc-sections -Wl,--strip-all>
    )
    
    message(STATUS "Android configuration applied - ABI: ${ANDROID_ABI}")

elseif(IS_IOS)
    # iOS-specific settings
    target_compile_definitions(${PROJECT_NAME} PRIVATE IOS_PLATFORM)
    
    # Debug-specific settings for iOS
    target_compile_options(${PROJECT_NAME} PRIVATE
        $<$<CONFIG:Debug>:-g -O0 -fno-omit-frame-pointer>
    )
    
    # Release-specific optimizations for iOS
    target_compile_options(${PROJECT_NAME} PRIVATE
        $<$<CONFIG:Release>:-O3 -DNDEBUG>
    )
    
    # iOS requires static libraries for frameworks
    if(NOT BUILD_SHARED_LIBS)
        set_target_properties(${PROJECT_NAME} PROPERTIES
            FRAMEWORK TRUE
            FRAMEWORK_VERSION ${PROJECT_VERSION_MAJOR}
            MACOSX_FRAMEWORK_IDENTIFIER bczl.xyz.framework
            PUBLIC_HEADER "${HEADERS}"
        )
    endif()
    
    # iOS deployment target
    if(NOT DEFINED DEPLOYMENT_TARGET)
        set(DEPLOYMENT_TARGET "13.0")
    endif()
    
    set_target_properties(${PROJECT_NAME} PROPERTIES
        XCODE_ATTRIBUTE_IPHONEOS_DEPLOYMENT_TARGET ${DEPLOYMENT_TARGET}
        XCODE_ATTRIBUTE_ENABLE_BITCODE NO
    )
    
    message(STATUS "iOS configuration applied - Platform: ${PLATFORM}, Deployment Target: ${DEPLOYMENT_TARGET}")

elseif(IS_MACOS)
    # macOS-specific settings
    target_compile_definitions(${PROJECT_NAME} PRIVATE MACOS_PLATFORM)
    
    # Debug-specific settings for macOS
    target_compile_options(${PROJECT_NAME} PRIVATE
        $<$<CONFIG:Debug>:-g -O0 -fno-omit-frame-pointer>
    )
    
    # Release-specific optimizations for macOS
    target_compile_options(${PROJECT_NAME} PRIVATE
        $<$<CONFIG:Release>:-O3 -DNDEBUG -fvisibility=hidden>
    )
    
    set_target_properties(${PROJECT_NAME} PROPERTIES
        MACOSX_RPATH TRUE
        INSTALL_NAME_DIR "@rpath"
        MACOSX_DEPLOYMENT_TARGET "10.15"
        OUTPUT_NAME "mmap2"
    )
    
    message(STATUS "macOS configuration applied")

elseif(IS_WINDOWS)
    # Windows-specific settings
    target_compile_definitions(${PROJECT_NAME} PRIVATE 
        WIN32_PLATFORM
        BUILDING_DLL
        _CRT_SECURE_NO_WARNINGS
    )
    
    # Debug-specific settings for Windows
    target_compile_options(${PROJECT_NAME} PRIVATE
        $<$<CONFIG:Debug>:/Zi /Od /MDd>
    )
    
    # Release-specific optimizations for Windows
    target_compile_options(${PROJECT_NAME} PRIVATE
        $<$<CONFIG:Release>:/O2 /DNDEBUG /MD>
    )
    
    set_target_properties(${PROJECT_NAME} PROPERTIES
        OUTPUT_NAME "mmap2"
        SUFFIX ".dll"
        WINDOWS_EXPORT_ALL_SYMBOLS TRUE
    )
    
    message(STATUS "Windows configuration applied")

elseif(IS_LINUX)
    # Linux-specific settings
    target_compile_definitions(${PROJECT_NAME} PRIVATE LINUX_PLATFORM)
    
    # Debug-specific settings for Linux
    target_compile_options(${PROJECT_NAME} PRIVATE
        $<$<CONFIG:Debug>:-g -O0 -fno-omit-frame-pointer>
    )
    
    # Release-specific optimizations for Linux
    target_compile_options(${PROJECT_NAME} PRIVATE
        $<$<CONFIG:Release>:-O3 -DNDEBUG -ffunction-sections -fdata-sections -fvisibility=hidden>
    )
    
    target_link_options(${PROJECT_NAME} PRIVATE
        $<$<CONFIG:Release>:-Wl,--gc-sections -Wl,--strip-all>
    )
    
    set_target_properties(${PROJECT_NAME} PROPERTIES
        OUTPUT_NAME "mmap2"
        SUFFIX ".so"
    )
    
    message(STATUS "Linux configuration applied")
endif()

# Development options
option(BUILD_EXAMPLES "Build examples" OFF)
option(BUILD_TESTS "Build tests" OFF)

if(BUILD_EXAMPLES)
    add_subdirectory(examples)
endif()

if(BUILD_TESTS)
    enable_testing()
    add_subdirectory(tests)
endif()

# Custom target for packaging desktop libraries
if(IS_WINDOWS OR IS_MACOS OR IS_LINUX)
    # Determine library extension and output directory
    if(IS_WINDOWS)
        set(LIB_EXTENSION ".dll")
        set(LIB_PREFIX "")
        set(PLATFORM_NAME "windows")
    elseif(IS_MACOS)
        set(LIB_EXTENSION ".dylib")
        set(LIB_PREFIX "lib")
        set(PLATFORM_NAME "macos")
    elseif(IS_LINUX)
        set(LIB_EXTENSION ".so")
        set(LIB_PREFIX "lib")
        set(PLATFORM_NAME "linux")
    endif()
    
    # Create package target
    add_custom_target(package
        COMMAND ${CMAKE_COMMAND} -E make_directory ${CMAKE_BINARY_DIR}/package
        COMMAND ${CMAKE_COMMAND} -E copy $<TARGET_FILE:${PROJECT_NAME}> ${CMAKE_BINARY_DIR}/package/
        COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_SOURCE_DIR}/include/mio_wrapper.h ${CMAKE_BINARY_DIR}/package/
        COMMAND ${CMAKE_COMMAND} -E tar cf ${CMAKE_BINARY_DIR}/${PROJECT_NAME}-${PROJECT_VERSION}-${PLATFORM_NAME}.zip --format=zip ${CMAKE_BINARY_DIR}/package/
        COMMAND ${CMAKE_COMMAND} -E echo "Package created: ${CMAKE_BINARY_DIR}/${PROJECT_NAME}-${PROJECT_VERSION}-${PLATFORM_NAME}.zip"
        DEPENDS ${PROJECT_NAME}
        COMMENT "Creating distribution package for ${PLATFORM_NAME}"
    )
    
    # Create package-all target for building multiple architectures
    if(IS_WINDOWS)
        add_custom_target(package-all
            COMMAND ${CMAKE_COMMAND} -E echo "Building Windows packages for multiple architectures..."
            COMMAND ${CMAKE_COMMAND} -E echo "Use scripts/build-windows.ps1 with different platforms to build all architectures"
            COMMENT "Building packages for all Windows architectures"
        )
    elseif(IS_MACOS)
        add_custom_target(package-all
            COMMAND ${CMAKE_COMMAND} -E echo "Building macOS universal package..."
            COMMAND ${CMAKE_COMMAND} -E echo "Use scripts/build-macos.sh universal to build universal binary"
            COMMENT "Building universal macOS package"
        )
    endif()
    
    message(STATUS "Added custom target 'package' for ${PLATFORM_NAME} distribution")
endif()

# Print configuration summary
message(STATUS "")
message(STATUS "mio_wrapper Configuration Summary:")
message(STATUS "  Version: ${PROJECT_VERSION}")
message(STATUS "  Build Type: ${CMAKE_BUILD_TYPE}")
message(STATUS "  Platform: ${CMAKE_SYSTEM_NAME}")
if(IS_ANDROID)
    message(STATUS "  Android ABI: ${ANDROID_ABI}")
endif()
if(IS_IOS)
    message(STATUS "  iOS Platform: ${PLATFORM}")
    message(STATUS "  iOS Deployment Target: ${DEPLOYMENT_TARGET}")
endif()
message(STATUS "  Library Type: $<IF:$<BOOL:${BUILD_SHARED_LIBS}>,Shared,Static>")
message(STATUS "  C++ Standard: ${CMAKE_CXX_STANDARD}")
message(STATUS "  Install Prefix: ${CMAKE_INSTALL_PREFIX}")
message(STATUS "")
