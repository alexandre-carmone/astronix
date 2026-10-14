{ pkgs, lib, ... }:

# CUDA for software nixpkgs did not build: pip/uv wheels (onnxruntime-gpu,
# jax, tensorflow...) and prebuilt binaries.
# They dlopen the CUDA libraries by soname. On NixOS none of them sit on a
# search path:
#   - libcuda, libnvidia-ml... come with the driver, in /run/opengl-driver/lib
#   - libcudart, libcublas, libcudnn... come from cudaPackages
# nix-ld does not help with uv venvs. Their python is the Nix python3, so it
# reads LD_LIBRARY_PATH, not NIX_LD_LIBRARY_PATH (see modules/astro.nix).
#
# Only the runtime libraries. nvcc and the headers are left out.
# The versions follow cudaPackages, nixpkgs' default CUDA (12.9).
# The 595 driver supports up to CUDA 13.
let
  cudaLibs = pkgs.buildEnv {
    name = "cuda-libs";
    pathsToLink = [ "/lib" ];
    paths = map lib.getLib (with pkgs.cudaPackages; [
      # The libraries of the CUDA toolkit.
      cuda_cudart
      cuda_cupti
      cuda_nvrtc
      cuda_nvtx
      libcublas
      libcufft
      libcufile
      libcurand
      libcusolver
      libcusparse
      libnpp
      libnvjitlink
      libnvjpeg
      # The deep learning libraries.
      cudnn
      libcusparse_lt
      libcutensor
      # NCCL is left out. It is compiled from source, and it only serves
      # multi-GPU training. Torch wheels bundle their own.
    ]);
  };
in
{
  # Wheels that bundle their own CUDA (torch) can pick up these libraries
  # instead, when they share a soname. A newer minor version usually works.
  environment.sessionVariables.LD_LIBRARY_PATH = [
    "/run/opengl-driver/lib"
    "${cudaLibs}/lib"
  ];
}
