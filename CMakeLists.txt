cmake_minimum_required(VERSION 3.25)
project(apostol-crm VERSION 2.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# ─── Project identity ─────────────────────────────────────────────────────────

set(APP_NAME        "apostol-crm"   CACHE STRING "Application name (used for paths, config, PID)")
set(APP_DESCRIPTION "Apostol CRM"   CACHE STRING "Application description (WWW Server-name header)")

message(STATUS "App name: ${APP_NAME}")
message(STATUS "App description: ${APP_DESCRIPTION}")

# ─── Settings ─────────────────────────────────────────────────────────────────

set(INSTALL_AS_ROOT  ON  CACHE BOOL   "Install to /usr/sbin and /etc (requires root)")

# Feature flags (set before add_subdirectory — libapostol picks them from cache)
set(WITH_POSTGRESQL  ON  CACHE BOOL   "Build with PostgreSQL (libpq)")
set(WITH_SSL         ON  CACHE BOOL   "Build with OpenSSL")
set(WITH_CURL        ON  CACHE BOOL   "Build with libcurl")

# Install paths
if(INSTALL_AS_ROOT)
    set(INSTALL_BIN_PATH "/usr/sbin")
    set(APP_PREFIX "/etc/${APP_NAME}")
else()
    set(INSTALL_BIN_PATH "/usr/local/sbin")
    set(APP_PREFIX "$ENV{HOME}/.config/${APP_NAME}")
endif()

# ─── Global compile options ──────────────────────────────────────────────────

add_compile_options("$<$<CONFIG:Debug>:-D_DEBUG>")

# clang-tidy (applied per-target, not globally — avoids linting dependencies)
option(ENABLE_CLANG_TIDY "Run clang-tidy during compilation" OFF)
if(ENABLE_CLANG_TIDY)
    find_program(CLANG_TIDY_EXE NAMES clang-tidy)
    if(CLANG_TIDY_EXE)
        message(STATUS "clang-tidy: ${CLANG_TIDY_EXE}")
    else()
        message(WARNING "ENABLE_CLANG_TIDY is ON but clang-tidy not found")
    endif()
endif()

if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release)
endif()

# ─── libapostol (core framework) ─────────────────────────────────────────────

add_subdirectory(src/lib/libapostol)

# APP_* compile definitions — applied to `apostol` target (PUBLIC → propagates
# to all consumers). libapostol itself does not set APP_* — the application does.
target_compile_definitions(apostol PUBLIC
    APP_NAME="${APP_NAME}"
    APP_DESCRIPTION="${APP_DESCRIPTION}"
    APP_DEFAULT_LOCALE="en_US.UTF-8"
    APP_VAR="${APP_NAME}"
    APP_OLDPID_EXT=".oldbin"
    APP_DEFAULT_USER="nobody"
    APP_DEFAULT_GROUP="nogroup"
    APP_DEFAULT_LISTEN="0.0.0.0"
    APP_PREFIX="${APP_PREFIX}/"
    APP_CONF_PREFIX="conf/"
    APP_CACHE_PREFIX="cache/"
    APP_SBIN_PATH="sbin/${APP_NAME}"
    APP_CONF_FILE="${APP_NAME}.json"
    APP_PID_FILE="logs/${APP_NAME}.pid"
    APP_LOCK_FILE="logs/${APP_NAME}.lock"
    APP_ERROR_LOG_FILE="logs/error.log"
    APP_ACCESS_LOG_FILE="logs/access.log"
    APP_POSTGRES_LOG_FILE="logs/postgres.log"
    APP_STREAM_LOG_FILE="logs/stream.log"
    APP_DOC_ROOT="www"
    APP_VERSION="${PROJECT_VERSION}"
    APP_DEFAULT_LOG_LEVEL="notice"
    APP_DEFAULT_LOG_MAX_SIZE=104857600
    APP_DEFAULT_LISTEN_BACKLOG=128
    APP_DEFAULT_WORKERS=1
    APP_DEFAULT_PORT=4977
    APP_DEFAULT_SERVER_TIMEOUT=5000
    APP_DEFAULT_PG_CONNECT_TIMEOUT=5
)

# ─── Build-time version header ───────────────────────────────────────────────

set(APOSTOL_VERSION_OUT "${CMAKE_BINARY_DIR}/include/apostol/version.hpp")

add_custom_target(apostol_version
    COMMAND ${CMAKE_COMMAND}
        -DSOURCE_DIR=${CMAKE_SOURCE_DIR}
        -DAPP_NAME=${APP_NAME}
        -DPROJECT_VERSION=${PROJECT_VERSION}
        -DPROJECT_VERSION_MAJOR=${PROJECT_VERSION_MAJOR}
        -DPROJECT_VERSION_MINOR=${PROJECT_VERSION_MINOR}
        -DPROJECT_VERSION_PATCH=${PROJECT_VERSION_PATCH}
        -DVERSION_IN=${CMAKE_SOURCE_DIR}/cmake/version.hpp.in
        -DVERSION_OUT=${APOSTOL_VERSION_OUT}
        -P ${CMAKE_SOURCE_DIR}/cmake/GenerateVersion.cmake
    BYPRODUCTS ${APOSTOL_VERSION_OUT}
    COMMENT "Generating version header"
)

# ─── Module & process auto-discovery ─────────────────────────────────────────

file(GLOB_RECURSE module_files  CONFIGURE_DEPENDS src/modules/*.cpp)
file(GLOB_RECURSE process_files CONFIGURE_DEPENDS src/processes/*.cpp)

message(STATUS "Module sources : ${module_files}")
message(STATUS "Process sources: ${process_files}")

# ─── Modules & processes library ─────────────────────────────────────────────

add_library(apostol_modules STATIC ${module_files} ${process_files})

target_include_directories(apostol_modules
    PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}/src/modules
        ${CMAKE_CURRENT_SOURCE_DIR}/src/modules/Workers
        ${CMAKE_CURRENT_SOURCE_DIR}/src/modules/Helpers
        ${CMAKE_CURRENT_SOURCE_DIR}/src/processes
        ${CMAKE_BINARY_DIR}/include          # generated apostol/version.hpp
)

target_link_libraries(apostol_modules PUBLIC apostol)

add_dependencies(apostol_modules apostol_version)

target_compile_options(apostol_modules PRIVATE
    -Wall -Wextra -Wpedantic -Wno-unused-parameter
)

if(ENABLE_CLANG_TIDY AND CLANG_TIDY_EXE)
    set_target_properties(apostol_modules PROPERTIES CXX_CLANG_TIDY "${CLANG_TIDY_EXE}")
endif()

# ─── Main executable ─────────────────────────────────────────────────────────

file(GLOB_RECURSE app_src_files CONFIGURE_DEPENDS src/app/*.cpp)

message(STATUS "App sources    : ${app_src_files}")

add_executable(apostol-crm ${app_src_files})

set_target_properties(apostol-crm PROPERTIES OUTPUT_NAME ${APP_NAME})

target_include_directories(apostol-crm PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/src/app
)

target_link_libraries(apostol-crm PRIVATE apostol_modules)

if(ENABLE_CLANG_TIDY AND CLANG_TIDY_EXE)
    set_target_properties(apostol-crm PROPERTIES CXX_CLANG_TIDY "${CLANG_TIDY_EXE}")
endif()

# ─── Tests ────────────────────────────────────────────────────────────────────

option(BUILD_TESTING "Build integration tests" OFF)

if(BUILD_TESTING)
    include(FetchContent)
    FetchContent_Declare(
        Catch2
        GIT_REPOSITORY https://github.com/catchorg/Catch2.git
        GIT_TAG        v3.7.1
    )
    FetchContent_MakeAvailable(Catch2)

    include(CTest)
    include(Catch)
endif()

# ─── Install ──────────────────────────────────────────────────────────────────

set(INSTALL_PATH "${APP_PREFIX}")

install(TARGETS apostol-crm DESTINATION ${INSTALL_BIN_PATH})

install(DIRECTORY DESTINATION ${INSTALL_PATH})
install(DIRECTORY DESTINATION ${INSTALL_PATH}/oauth2)
install(DIRECTORY DESTINATION ${INSTALL_PATH}/conf)
install(DIRECTORY DESTINATION ${INSTALL_PATH}/logs)
install(DIRECTORY DESTINATION ${INSTALL_PATH}/cache)
install(DIRECTORY DESTINATION ${INSTALL_PATH}/sites)

install(DIRECTORY conf/oauth2/ DESTINATION ${INSTALL_PATH}/oauth2)
install(DIRECTORY conf/sites/ DESTINATION ${INSTALL_PATH}/sites)

# Install default config if present
if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/conf/default.json")
    install(FILES conf/default.json DESTINATION ${INSTALL_PATH} RENAME ${APP_NAME}.json)
endif()

# systemd unit
if(INSTALL_AS_ROOT)
    if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/auto/unit.service")
        install(FILES auto/unit.service
            DESTINATION /lib/systemd/system
            RENAME ${APP_NAME}.service
            PERMISSIONS OWNER_READ OWNER_WRITE GROUP_READ WORLD_READ)
        install(CODE "execute_process(COMMAND systemctl daemon-reload)")
        install(CODE "execute_process(COMMAND systemctl enable ${APP_NAME}.service)")
    endif()
endif()
