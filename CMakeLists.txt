cmake_minimum_required(VERSION 3.20)
project(<project_name> LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Debug)
endif()

if(APPLE AND EXISTS "/opt/homebrew")
    list(PREPEND CMAKE_PREFIX_PATH "/opt/homebrew")
endif()

option(ENABLE_TESTS "Build unit tests" ON)
option(ENABLE_APP "Build app (production CLI)" ON)
option(ENABLE_DEV_MAIN "Build dev_main executable (experiments)" ON)
option(ENABLE_SANITIZERS "ASan + UBSan in Debug" ON)

file(GLOB_RECURSE CORE_SOURCES CONFIGURE_DEPENDS
        "${CMAKE_CURRENT_SOURCE_DIR}/src/*.cpp"
)
add_library(core_lib STATIC ${CORE_SOURCES})

target_include_directories(core_lib PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}/header
)

file(GLOB_RECURSE CORE_HEADERS CONFIGURE_DEPENDS
        "${CMAKE_CURRENT_SOURCE_DIR}/header/*.hpp"
        "${CMAKE_CURRENT_SOURCE_DIR}/header/*.h"
)
target_sources(core_lib PRIVATE ${CORE_HEADERS})

target_compile_options(core_lib PUBLIC -Wall -Wextra -Wpedantic)

if(ENABLE_SANITIZERS AND CMAKE_BUILD_TYPE STREQUAL "Debug")
    target_compile_options(core_lib PUBLIC -fsanitize=address,undefined -fno-omit-frame-pointer)
    target_link_options(core_lib PUBLIC -fsanitize=address,undefined)
endif()

# --- Production CLI app ---
if(ENABLE_APP AND EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/app/main.cpp")
    add_executable(app app/main.cpp)
    target_link_libraries(app PRIVATE core_lib)
endif()

# --- Dev / scratch main ---
if(ENABLE_DEV_MAIN AND EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/app/dev_main.cpp")
    add_executable(dev_main app/dev_main.cpp)
    target_link_libraries(dev_main PRIVATE core_lib)
    target_compile_definitions(dev_main PRIVATE DEV_MAIN_BUILD=1)
endif()

# --- Unit tests ---
if(ENABLE_TESTS AND EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/unit_tests/CMakeLists.txt")
    enable_testing()
    add_subdirectory(unit_tests)
endif()
