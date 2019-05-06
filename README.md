# Parallel-PoW(Proof of Work)

## Overview
This program finds hash to prove of own's work using GPU power not CPU intensive.

## How to run
<ul>
  <li> Visual Studio 2015 or Visual Studio 2017 설치 </li>
  <li> Cuda 9.0 설치 </li>
  <li> NVIDIA 프로젝트 생성 후 소스파일 생성 </li>
  <li> CUDA 프로그램은 1~2초 안에 프로그램이 정상종료되지않을 경우 프로그램이 강제 . 따라서 연산이 오래걸리는 프로그램을 실행시키기 위해서는 반드시 Nsight monitor 프로그램에서 window tdr을 disable로 설정해야한다. </li>
</ul>


## Environtment
<p>Platform : Window 10</p>
<p>Compiler : NVCC + MSVC</p>
<p>CPU : intel i7</p>
<p>GPU : GTX1050</p>




## Result

### GPU
![캡처_6자리](https://user-images.githubusercontent.com/12508269/57239347-9af17000-7066-11e9-89b2-c04efb839a11.PNG)
4.3sec

### CPU
![cpu2](https://user-images.githubusercontent.com/12508269/57239350-9b8a0680-7066-11e9-989c-b53022d53e08.PNG)
8m 55sec
<br/>
# of zero is 7 but, this is fortunate case. in this case I have set the difficulty is at least six. so this is not wrong result.


