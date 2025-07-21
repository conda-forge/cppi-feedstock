#!/usr/bin/env bash

set -o xtrace -o nounset -o pipefail -o errexit

if [[ "${CONDA_BUILD_CROSS_COMPILATION:-}" == "1" ]]; then
    CROSS_LDFLAGS=${LDFLAGS}
    CROSS_AR="${AR}"
    CROSS_CC="${CC}"
    CROSS_LD="${LD}"
    CROSS_RANLIB="${RANLIB}"

    LDFLAGS=${LDFLAGS//${PREFIX}/${BUILD_PREFIX}}
    AR=${AR//${CONDA_TOOLCHAIN_HOST}/${CONDA_TOOLCHAIN_BUILD}}
    CC=${CC//${CONDA_TOOLCHAIN_HOST}/${CONDA_TOOLCHAIN_BUILD}}
    LD="${LD//${CONDA_TOOLCHAIN_HOST}/${CONDA_TOOLCHAIN_BUILD}}"
    RANLIB="${RANLIB//${CONDA_TOOLCHAIN_HOST}/${CONDA_TOOLCHAIN_BUILD}}"

    autoreconf --force --verbose --install
    ./configure --disable-silent-rules \
        --disable-dependency-tracking \
        --prefix=${BUILD_PREFIX}

    make -j${CPU_COUNT} install
    make clean

    LDFLAGS="${CROSS_LDFLAGS}"
    AR=${CROSS_AR}
    CC=${CROSS_CC}
    LD=${CROSS_LD}
    RANLIB=${CROSS_RANLIB}

    sed -i "s?\$\$prog\$(EXEEXT)?${BUILD_PREFIX}/bin/cppi?" man/local.mk
fi

autoreconf --force --verbose --install
./configure --disable-silent-rules \
    --disable-dependency-tracking \
    --prefix=${PREFIX}
if [[ ${CONDA_BUILD_CROSS_COMPILATION:-0} == 0 ]]; then
    if [[ ${target_platform} != "linux-ppc64le" ]] && [[ ${target_platform} != "linux-aarch64" ]]; then
        make -j${CPU_COUNT} check
    fi
fi
make -j${CPU_COUNT} install
