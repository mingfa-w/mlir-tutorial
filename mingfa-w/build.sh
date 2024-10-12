#!/bin/bash
# bash build.sh 不添加参数表示增量编译
# bash build.sh 0 带参数0表示重新编译
current_dir=$(cd $(dirname $0); pwd)
export rebuild=$1 # 0: 全新编译
ARCH=`uname -m`
LLVM_MAJ_VER=main #17

# mlirToy path
mlirToy_src_dir=${current_dir}/..
mlirToy_build_dir=${current_dir}/build
mlirToy_install_dir=${mlirToy_build_dir}/install
mlirToy_dir=${mlirToy_install_dir}/lib

if [ ! $LLVM_CMAKE_PATH ]; then
  LLVM_CMAKE_PATH=$HOME/.local/llvm-${LLVM_MAJ_VER}-${ARCH}/lib/cmake/llvm
  if [ ! -d ${LLVM_CMAKE_PATH} ]; then
    LLVM_CMAKE_PATH=`llvm-config --cmakedir`
  fi
fi
echo "use LLVM_CMAKE_PATH ${LLVM_CMAKE_PATH}"

LLVM_CMAKE_DIR=$(readlink -f ${LLVM_CMAKE_PATH})
MLIR_CMAKE_DIR=$(readlink -f ${LLVM_CMAKE_PATH}/../mlir)

git submodule update --init --recursive

build_mlirToy() {
    echo === building mlirToy ===
    # 如果参数为0或1，则删除build目录，重新生成makefile，再编译
    if [ ! -z ${rebuild} ]; then
        if [ ${rebuild} == 0 ] || [ ${rebuild} == 1 ]; then
            echo ==== restrat to build mlirToy, please input: y/n ====
            read input
            # input='y'
            if [ ${input} == 'y' ]; then
                echo ========= remove ${mlirToy_build_dir} =======
                rm -rf ${mlirToy_build_dir} ${mlirToy_install_dir}
            fi
        fi
    fi

    # 如果没有build目录，则创建并重新生成makefile
    if [ ! -d ${mlirToy_build_dir} ]; then
        mkdir -p ${mlirToy_build_dir}
        mkdir -p ${mlirToy_install_dir}
        LLVM_TOOLS=" -DCMAKE_C_COMPILER="clang" \
                    -DCMAKE_CXX_COMPILER="clang++"
                  "

        cmake -G Ninja -S ${mlirToy_src_dir} -B ${mlirToy_build_dir} \
            -DCMAKE_BUILD_TYPE="Debug" \
            -DCMAKE_INSTALL_PREFIX=${mlirToy_install_dir} \
            -DCMAKE_CXX_STANDARD=17 \
            -DLLVM_CMAKE_DIR=${LLVM_CMAKE_DIR} \
            -DMLIR_CMAKE_DIR=${MLIR_CMAKE_DIR} \
            ${LLVM_TOOLS}
    fi
    # ninja -C ${mlirToy_build_dir} -j $(nproc)
    # ninja -C ${mlirToy_build_dir} -j $(nproc) check
    # 编译header是为了tablegen文件修改了之后重新生成
    ninja -C ${mlirToy_build_dir} -j $(nproc)
    # ninja -C ${mlirToy_build_dir} -j $(nproc) install
}

# build mlirToy
build_mlirToy
result=$?
if [ $result -eq 0 ]; then
  # echo "Please add the follwing environment variables"
  # echo "export mlirToy_INS_DIR=$mlirToy_install_dir"
  # echo "export mlirToy_DIR=$mlirToy_dir"
  # echo "export PATH=\$mlirToy_INS_DIR/bin:\$PATH"
  echo " ==== debug ===== "
  echo " export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:./build "
  echo " export mlirToy_PATH=$(pwd)/stdlib/mlirToy "
  echo " gdb --args build/unittests/mlirToy/mlirToyt py -bc unittests/mlirToy/fib.mlirToy "
fi


