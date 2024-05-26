cmake_minimum_required(VERSION 3.10)
project(stockfish)

# Set the C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Installation dir definitions
set(CMAKE_INSTALL_PREFIX "/usr/local")

# Download nnue
execute_process(
    COMMAND ../nnue/download_nnue.sh
    OUTPUT_VARIABLE _OUTPUT_MSG
    ERROR_VARIABLE _ERROR_VARIABLE
)
message(STATUS "${_OUTPUT_MSG}")
if(_ERROR_VARIABLE)
    message(FATAL_ERROR "ERROR_VARIABLE: ${ERROR_VARIABLE}")
endif()

# Source and header files
set(SRCS
    src/benchmark.cpp
    src/bitboard.cpp
    src/evaluate.cpp
    src/misc.cpp
    src/movegen.cpp
    src/movepick.cpp
    src/position.cpp
    src/search.cpp
    src/thread.cpp
    src/timeman.cpp
    src/tt.cpp
    src/uci.cpp
    src/ucioption.cpp
    src/tune.cpp
    src/syzygy/tbprobe.cpp
    src/nnue/evaluate_nnue.cpp
    src/nnue/features/half_ka_v2_hm.cpp
)

add_library(stockfish_engine SHARED ${SRCS})
include_directories(
    src
    src/nnue
    src/nnue/features
    src/nnue/layers
    src/syzygy
)

# Setting up compiler flags
set(CXXFLAGS -Wall -Wcast-qual -fno-exceptions -std=c++17 ${CMAKE_CXX_FLAGS})
set(LDFLAGS)

# Architecture settings
if(NOT ARCH)
    execute_process(
        COMMAND ../scripts/get_native_properties.sh
        OUTPUT_VARIABLE _OUTPUT_MSG
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    string(REGEX MATCHALL "[^ ]+" _OUTPUT_VALUES "${_OUTPUT_MSG}")
    list(GET _OUTPUT_VALUES 0 ARCH)
endif()

set(SUPPORTED_ARCH
    x86-64-vnni512
    x86-64-vnni256
    x86-64-avx512
    x86-64-avxvnni
    x86-64-bmi2
    x86-64-avx2
    x86-64-sse41-popcnt
    x86-64-ssse3
    x86-64-sse3-popcnt
    x86-64
    x86-32-sse41-popcnt
    x86-32-sse2
    x86-32
    armv7
    armv7-neon
    armv8
    armv8-dotprod
)
set(SUPPORTED "NO")
foreach(_VALUE IN LISTS SUPPORTED_ARCH)
    if(_VALUE STREQUAL ARCH)
        set(SUPPORTED "YES")
        break()
    endif()
endforeach()
if(SUPPORTED STREQUAL "NO")
    message(FATAL_ERROR "Arch not support:${ARCH}")
endif()

message(STATUS "Arch: ${ARCH}")

set(BITS "64")
set(PREFETCH "NO")
set(POPCNT "NO")
set(PEXT "NO")
set(SSE "NO")
set(MMX "NO")
set(SSE2 "NO")
set(SSSE3 "NO")
set(SSE41 "NO")
set(AVX2 "NO")
set(AVXVNNI "NO")
set(AVX512 "NO")
set(VNNI256 "NO")
set(VNNI512 "NO")
set(NEON "NO")
set(DOTPROD "NO")
set(ARM_VERSION "0")

if(ARCH MATCHES "x86")
    # x86-32/64
    if(ARCH MATCHES "x86-32")
        set(SPEC_ARCH "i386")
        set(BITS "32")
        set(SSE "NO")
        set(MMX "YES")
    else()
        set(SPEC_ARCH "x86_64")
        set(SSE "YES")
        set(SSE2 "YES")
    endif()

    if(ARCH MATCHES "-sse")
        set(SSE "YES")
    endif()

    if(ARCH MATCHES "-popcnt")
        set(POPCNT "YES")
    endif()

    if(ARCH MATCHES "-mmx")
        set(MMX "YES")
    endif()

    if(ARCH MATCHES "-sse2")
        set(SSE "YES")
        set(SSE2 "YES")
    endif()

    if(ARCH MATCHES "-ssse3")
        set(SSE "YES")
        set(SSE2 "YES")
        set(SSSE3 "YES")
    endif()

    if(ARCH MATCHES "-sse41")
        set(SSE "YES")
        set(SSE2 "YES")
        set(SSSE3 "YES")
        set(SSE41 "YES")
    endif()

    if(ARCH MATCHES "-avx2")
        set(POPCNT "YES")
        set(SSE "YES")
        set(SSE2 "YES")
        set(SSSE3 "YES")
        set(SSE41 "YES")
        set(AVX2 "YES")
    endif()

    if(ARCH MATCHES "-avxvnni")
        set(POPCNT "YES")
        set(SSE "YES")
        set(SSE2 "YES")
        set(SSSE3 "YES")
        set(SSE41 "YES")
        set(AVX2 "YES")
        set(AVXVNNI "YES")
        set(PEXT "YES")
    endif()

    if(ARCH MATCHES "-bmi2")
        set(POPCNT "YES")
        set(SSE "YES")
        set(SSE2 "YES")
        set(SSSE3 "YES")
        set(SSE41 "YES")
        set(AVX2 "YES")
        set(PEXT "YES")
    endif()

    if(ARCH MATCHES "-avx512")
        set(POPCNT "YES")
        set(SSE "YES")
        set(SSE2 "YES")
        set(SSSE3 "YES")
        set(SSE41 "YES")
        set(AVX2 "YES")
        set(PEXT "YES")
        set(AVX512 "YES")
    endif()

    if(ARCH MATCHES "-vnni256")
        set(POPCNT "YES")
        set(SSE "YES")
        set(SSE2 "YES")
        set(SSSE3 "YES")
        set(SSE41 "YES")
        set(AVX2 "YES")
        set(PEXT "YES")
        set(VNNI256 "YES")
    endif()

    if(ARCH MATCHES "-vnni512")
        set(POPCNT "YES")
        set(SSE "YES")
        set(SSE2 "YES")
        set(SSSE3 "YES")
        set(SSE41 "YES")
        set(AVX2 "YES")
        set(PEXT "YES")
        set(AVX512 "YES")
        set(VNNI512 "YES")
    endif()

    if(SSE STREQUAL "YES")
        set(PREFETCH "YES")
    endif()

    # 64-bit pext is not available on x86-32
    if(BITS STREQUAL "32")
        set(PEXT "NO")
    endif()
else()
    # all other architectures
    if(ARCH STREQUAL "armv7")
        set(SPEC_ARCH "armv7")
        set(PREFETCH "YES")
        set(BITS "32")
        set(ARM_VERSION "7")
    endif()

    if(ARCH STREQUAL "armv7-neon")
        set(SPEC_ARCH "armv7")
        set(PREFETCH "YES")
        set(POPCNT "YES")
        set(NEON "YES")
        set(BITS "32")
        set(ARM_VERSION "7")
    endif()

    if(ARCH STREQUAL "armv8")
        set(SPEC_ARCH "armv8")
        set(PREFETCH "YES")
        set(POPCNT "YES")
        set(NEON "YES")
        set(ARM_VERSION "8")
    endif()

    if(ARCH STREQUAL "armv8-dotprod")
        set(SPEC_ARCH "armv8")
        set(PREFETCH "YES")
        set(POPCNT "YES")
        set(NEON "YES")
        set(DOTPROD "YES")
        set(ARM_VERSION "8")
    endif()
endif()

# Compiler specific settings
if(NOT COMP)
    set(COMP "gcc")
endif()

if(COMP STREQUAL "gcc")
    set(CXX "g++")
    set(CXXFLAGS ${CXXFLAGS} -pedantic -Wextra -Wshadow -Wmissing-declarations -m${BITS} -DUSE_PTHREADS)
    set(LDFLAGS ${LDFLAGS} -m${BITS} -Wl,--no-as-needed -lpthread)
endif()

if(BITS STREQUAL "64")
    set(CXXFLAGS ${CXXFLAGS} -DIS_64BIT)
endif()

# prefetch and popcount
if(PREFETCH STREQUAL "YES")
    if(SSE STREQUAL "YES")
        set(CXXFLAGS ${CXXFLAGS} -msse)
    endif()
else()
    set(CXXFLAGS ${CXXFLAGS} -DNO_PREFETCH)
endif()

if(POPCNT STREQUAL "YES")
    if(SPEC_ARCH STREQUAL "armv7" OR SPEC_ARCH STREQUAL "armv8")
        set(CXXFLAGS ${CXXFLAGS} -DUSE_POPCNT)
    else()
        set(CXXFLAGS ${CXXFLAGS} -msse3 -mpopcnt -DUSE_POPCNT)
    endif()
endif()

if(AVX2 STREQUAL "YES")
    set(CXXFLAGS ${CXXFLAGS} -DUSE_AVX2 -mavx2 -mbmi)
endif()

if(AVXVNNI STREQUAL "YES")
    set(CXXFLAGS ${CXXFLAGS} -DUSE_VNNI -DUSE_AVXVNNI -mavxvnni)
endif()

if(AVX512 STREQUAL "YES")
    set(CXXFLAGS ${CXXFLAGS} -DUSE_AVX512 -mavx512f -mavx512bw)
endif()

if(VNNI256 STREQUAL "YES")
    set(CXXFLAGS ${CXXFLAGS} -DUSE_VNNI -mavx512f -mavx512bw -mavx512vnni -mavx512dq -mavx512vl -mprefer-vector-width=256)
endif()

if(VNNI512 STREQUAL "YES")
    set(CXXFLAGS ${CXXFLAGS} -DUSE_VNNI -mavx512f -mavx512bw -mavx512vnni -mavx512dq -mavx512vl -mprefer-vector-width=512)
endif()

if(SSE41 STREQUAL "YES")
    set(CXXFLAGS ${CXXFLAGS} -DUSE_SSE41 -msse4.1)
endif()

if(SSSE3 STREQUAL "YES")
    set(CXXFLAGS ${CXXFLAGS} -DUSE_SSSE3 -mssse3)
endif()

if(SSE2 STREQUAL "YES")
    set(CXXFLAGS ${CXXFLAGS} -DUSE_SSE2 -msse2)
endif()

if(MMX STREQUAL "YES")
    set(CXXFLAGS ${CXXFLAGS} -mmmx)
endif()

if(NEON STREQUAL "YES")
    set(CXXFLAGS ${CXXFLAGS} -DUSE_NEON=$(ARM_VERSION))
    if(NOT SPEC_ARCH STREQUAL "armv8")
        set(CXXFLAGS ${CXXFLAGS} -mfpu=neon)
    endif()
endif()

if(DOTPROD STREQUAL "YES")
    set(CXXFLAGS ${CXXFLAGS} -march=armv8.2-a+dotprod -DUSE_NEON_DOTPROD)
endif()

if(PEXT STREQUAL "YES")
    set(CXXFLAGS ${CXXFLAGS} -DUSE_PEXT -mbmi2)
endif()

set(CXXFLAGS ${CXXFLAGS} -DARCH=${ARCH})

# Debugging
option(DEBUG "Enable debugging" OFF)
if(DEBUG)
    set(CXXFLAGS ${CXXFLAGS} -g)
else()
    set(CXXFLAGS ${CXXFLAGS} -DNDEBUG)
endif()

# Optimization
option(OPTIMIZE "Enable optimizations" ON)
if(OPTIMIZE)
    set(CXXFLAGS ${CXXFLAGS} -O3 -funroll-loops)
    if(ANDROID)
        set(CXXFLAGS ${CXXFLAGS} -fno-gcse -mthumb -march=armv7-a -mfloat-abi=softfp)
    endif()
endif()

# Link Time Optimization
if(OPTIMIZE AND NOT DEBUG)
    set(CXXFLAGS ${CXXFLAGS} -flto -flto-partition=one)
    set(LDFLAGS ${LDFLAGS} ${CXXFLAGS} -flto=jobserver)
endif()

if(ANDROID)
    set(CXXFLAGS ${CXXFLAGS} -fPIE)
    set(LDFLAGS ${LDFLAGS} -fPIE -pie)
endif()

message(STATUS "CXXFLAGS: ${CXXFLAGS}")
message(STATUS "LDFLAGS: ${LDFLAGS}")

# Set compiler and linker flags
target_compile_options(stockfish_engine PRIVATE ${CXXFLAGS})
target_link_options(stockfish_engine PRIVATE ${LDFLAGS})

# Build executable
add_executable(stockfish src/main.cpp)
target_link_libraries(stockfish PRIVATE stockfish_engine)
target_compile_options(stockfish PRIVATE ${CXXFLAGS})
target_link_options(stockfish PRIVATE ${LDFLAGS})
