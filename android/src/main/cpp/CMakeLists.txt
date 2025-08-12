cmake_minimum_required(VERSION 3.18.1)

project("libdivecomputer-java")

# Set C++ standard
set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Find required packages
find_library(log-lib log)

# Add the libdivecomputer-java native library
add_library(
    libdivecomputer-java
    SHARED
    exception.c
    org_libdivecomputer_Context.c
    org_libdivecomputer_Custom.c
    org_libdivecomputer_Descriptor.c
    org_libdivecomputer_Device.c
    org_libdivecomputer_IOStream.c
    org_libdivecomputer_Parser.c
    org_libdivecomputer_Serial.c
)

# Include directories
target_include_directories(
    libdivecomputer-java
    PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
)

# Link libraries
target_link_libraries(
    libdivecomputer-java
    ${log-lib}
)

# Compiler flags
target_compile_options(
    libdivecomputer-java
    PRIVATE
    -Wall
    -Wextra
    -O2
)