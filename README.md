# PerformanceExperiments
CPU and GPU performance experiments for educational purposes.

Ideas:
- Push as much geometry as possible from CPU to GPU on each thread. Observe DRAM bandwidth.
- Make a resource resident and non-resident. What happens on PCIe?
- Implement Mandelbrot fractal on CPU (scalar, vectorized, vectorized unrolled, multithreaded) and GPU (simple impl., impl. that uses HLSL 6 wave instructions to fetch work as soon as given vector lane finshes).
