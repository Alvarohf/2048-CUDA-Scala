# 2048-CUDA-Scala
Version of the game 2048 implemented in CUDA and Scala with bigger sizes.
## CUDA
CUDA is a language created by NVIDIA that allows you to work with your NVIDIA Graphic card (Not all architectures are supported). GPU programming is used with images, sound, simulations and big matrices. The reason is that it uses an architecture based on SIMD, SPMD (Singel Program Multiple Data), this means each core of the GPU could run a small part of code with different data, a big version of threads of CPUs. So we have used it to implement our game 2048 with matrices.
### How to play it
**Requirements**
* Have a NVIDIA GPU
* Must support CUDA

**Playing the game**
1. You have to compile the .cu file
2. Using CMD or powershell you have to call the executable file
   1. You have to pass the mode (-m: manual -a: automatic)
   2. You have to pass the difficulty (1: easy 2: hard)
   3. Number of columns
   4. Number of arrows
   5. Example 16384.exe -m 2 10 10 (Game in manual mode, hard with size 10x10)
 3. You can move the numbers with w,a,s,d or arrows
 4. You lose when you are unable to move in any direction
 5. You can save your game pressing g and exit pressing e
 6. You can play until you have 0 lifes.
 ![Image of game](https://github.com/Alvarohf/2048-CUDA-Scala/blob/master/image_1_Running_game.png)
 ![Image of specs](https://github.com/Alvarohf/2048-CUDA-Scala/blob/master/image_3_Graphic_card_spec.png)
 ![Image of file](https://github.com/Alvarohf/2048-CUDA-Scala/blob/master/image_2_Saved_game.png)
### Versions
There are two versions of the game implemented in CUDA, they are almost identical but the GPU implementation is a bit different.
* **Normal version:** this version use threads provided by CUDA, but with less parallelism. So it will have less performance.
* **Blocks version:** this version use blocks of thread, using a grid passed by parameter. It gives an extra parallelism that CUDA cores can use to get a better perfomance using more cores to calculate data.
## Scala
Also it has been made in Scala in a functional way. It works the same way above but in Scala using less functionalities of console.
There hasnt been used for/whiles and variables.
### How to play it
**Requirements**
* Have Java SDK
**Playing the game**
1. You have to compile the .scala with javac or scalac
2. Using CMD you call the compiled file
3. It will ask you for parameters
4. Same game logic as before
