/*====================================================================================
|                 Luis Alejandro Cabanillas Prudencio                                |
|                     Álvaro de las Heras Fernández                                  |
|                                                                                    |
|         16384 Juego que simula al 2048 implementado con matrices y CUDA            |
====================================================================================*/

//Librerias de CUDA
#include "cuda_runtime.h" 
#include "device_launch_parameters.h" 
#include "curand_kernel.h"
#include <cuda.h>

//Librerias de C y C++
#include <stdio.h>
#include <time.h>
#include <conio.h>
#include <stdlib.h>
#include <string.h>
#include <windows.h>
#define TILE_WIDTH 2

//Cabeceras de las funciones implmentadas en CPU
int generarNumeros(bool dificultad);
int* inicializarMatriz(int p_num_columnas, int p_num_filas, bool dificultad, int p_semillas_alta, int p_semillas_baja);
void imprimirMatrizVector(int* p_matriz_vector, int p_num_columnas, int p_num_filas);
bool contiene(int p_valor, int* semillas, int p_tam);
int* generaIndexSemilla(int p_num_columnas, int p_num_filas, int p_tam);
void modoManual(int* p_tablero, int p_num_columnas, int p_num_filas, bool p_dificultad, int p_semillas_baja, int p_semillas_alta);
void modoAutomatico(int* p_tablero, int p_num_columnas, int p_num_filas, bool p_dificultad, int p_semillas_baja, int p_semillas_alta);
void guardarPartida(int* tablero, int vidas, int puntuacion, int p_num_columnas, int p_num_filas);
int* cargarPartida(int* p_vidas, int* p_puntuacion, int* p_num_columnas, int* p_num_filas);
int comprobarCasillasVacias(int * p_tablero, int p_num_columnas, int p_num_filas);
int* rellenarTablero(int* p_tablero, int p_num_columnas, int p_num_filas, bool p_dificultad, int p_semillas_alta, int p_semillas_baja, bool* p_lleno);
void obtenerCaracteristicasCUDA(int p_num_columnas, int p_num_filas);
void Color(int fondo, int fuente);
void guardarRecord(int p_record);
int cargarRecord();

//Funciones que se ejecutaran en la GPU de NVIDIA
/**
* Funcion que mueve los valores y los suma (si son iguales) hacia abajo moviendo los 0 a la zona superior
* @param M_dev Tablero con los datos sobre el que se realizaran las operaciones
* @param p_num_columnas Numero de columnas del tablero
* @param p_num_filas Numero de filas del tablero
*/
__global__ void  moverAbajo(int* M_dev, int p_num_columnas, int p_num_filas, int* p_puntuacion_dev) {
	//Obtendra la suma que se añadir a la puntuacion
	int suma = 0;
	//Primero quitamos los 0 de la matriz para ello cada hilo ira bajando los valores
	//de la matriz de arriba si no son 0 esto se hara varias veces hasta asegurarse de que este completo
	for (int i = 0; i < p_num_filas; i++) {
		//En caso de que el valor del hilo es 0 se mueve
		if (M_dev[threadIdx.x] == 0) {
			//Hay que asegurarse de no pasarse de rango de la columna
			if (threadIdx.x >= p_num_columnas)
				//Si es distinto de 0 el valor anterior se procede a bajar
				if (!(M_dev[threadIdx.x - p_num_columnas] == 0)) {
					//Se reemplaza el valor de la casilla actual por el anterior
					M_dev[threadIdx.x] = M_dev[threadIdx.x - p_num_columnas];
					//Se deja la casilla anterior a 0 para que pueda ser ocupada por otros valores
					M_dev[threadIdx.x - p_num_columnas] = 0;
				}
		}
		//Sincronizamos los hilos para  asegurarnos de que acaban juntos
		__syncthreads();
	}
	//Una vez tenemos juntos los valores se suman los valores contiguos si son iguales
		//Al igual que antes comenzamos por el ultimo valor
	for (int k = (p_num_filas - 1); k > 0; k--) {
		//Nos aseguramos de que haya un hilo por columna
		if ((threadIdx.x / p_num_columnas) == k) {
			//Ademas vemos que no se accedan a zonas que puedan dar fallo
			if (threadIdx.x >= p_num_columnas) {
				//Se comprueba que la casilla no sea 0
				if (M_dev[threadIdx.x - p_num_columnas] >= 0) {
					//Se comprueba si son iguales para sumar valores
					if (M_dev[threadIdx.x] == M_dev[threadIdx.x - p_num_columnas])
					{
						suma = M_dev[threadIdx.x] * 2;
						//Si son iguales se suman los valores dando como resultado el doble
						M_dev[threadIdx.x] = M_dev[threadIdx.x] * 2;
						//La casilla anterior se deja a 0
						M_dev[threadIdx.x - p_num_columnas] = 0;
					}
				}
			}
		}
		//Se sincronizan los hilos en cada suma
		__syncthreads();
	}
	//Se vuelven a quitar los 0 tras sumar para dejar un resultado mas agradable
	//Primero quitamos los 0 de la matriz para ello cada hilo ira bajando los valores
	//de la matriz de arriba si no son 0 esto se hara varias veces hasta asegurarse de que este completo
	for (int i = 0; i < p_num_filas; i++) {
		//En caso de que el valor del hilo es 0 se mueve
		if ((M_dev[threadIdx.x] == 0)) {
			//Hay que asegurarse de no pasarse de rango de la columna
			if (threadIdx.x >= (p_num_columnas))
				//Si es distinto de 0 el valor anterior se procede a bajar
				if (!(M_dev[threadIdx.x - p_num_columnas] == 0)) {
					//Se reemplaza el valor de la casilla actual por el anterior
					M_dev[threadIdx.x] = M_dev[threadIdx.x - (p_num_columnas)];
					//Se deja la casilla anterior a 0 para que pueda ser ocupada por otros valores
					M_dev[threadIdx.x - (p_num_columnas)] = 0;
				}
		}
	}
	//Para obtener la puntuacion nos aseguramos de cada hilo sume en orden la suma de puntos a la variable
	for (int i = 0; i < (p_num_columnas*p_num_filas); i++) {
		if (threadIdx.x == i) {
			*p_puntuacion_dev = *p_puntuacion_dev + suma;
		}
		//Hacemos que esperen a la ejecucion de la instruccion
		__syncthreads();
	}
}
/**
* Funcion que mueve los valores y los suma (si son iguales) hacia arriba moviendo los 0 a la zona inferior
* @param M_dev Tablero con los datos sobre el que se realizaran las operaciones
* @param p_num_columnas Numero de columnas del tablero
* @param p_num_filas Numero de filas del tablero
*/
__global__ void  moverArriba(int* M_dev, int p_num_columnas, int p_num_filas, int* p_puntuacion_dev) {
	//Obtendra la suma que se añadir a la puntuacion
	int suma = 0;
	//Primero quitamos los 0 de la matriz para ello cada hilo ira subiendo los valores
	//de la matriz de abajo si no son 0 esto se hara varias veces hasta asegurarse de que este completo
	for (int i = 0; i < p_num_filas; i++) {
		//En caso de que el valor del hilo es 0 se mueve
		if ((M_dev[threadIdx.x] == 0)) {
			//Hay que asegurarse de no pasarse de rango de la columna
			if ((threadIdx.x + p_num_columnas) <= (p_num_columnas*p_num_filas))
				//Si es distinto de 0 el valor anterior se procede a bajar
				if (!(M_dev[threadIdx.x + p_num_columnas] == 0)) {

					//Se reemplaza el valor de la casilla actual por el de despues
					M_dev[threadIdx.x] = M_dev[threadIdx.x + (p_num_columnas)];
					//Se deja la casilla posterior a 0 para que pueda ser ocupada por otros valores
					M_dev[threadIdx.x + (p_num_columnas)] = 0;
				}
		}
		//Sincronizamos los hilos para  asegurarnos de que acaban juntos
		__syncthreads();
	}

	//Sumamos los numeros
	//Para ello tenemos que tener cuidado con la concurrencia por lo que se deja 1 hilo por
	//columna ademas se empieza de menor hilo a mayor hilo
	for (int k = 0; k < p_num_filas; k++) {
		//Nos aseguramos de que sean hilos de distintas columnas
		if ((threadIdx.x / p_num_columnas) == k) {
			//Nos aseguramos de que se encuentre en memoria
			if (M_dev[threadIdx.x + p_num_columnas] >= 0) {
				//Si son iguales se procede a la suma
				if (M_dev[threadIdx.x] == M_dev[threadIdx.x + p_num_columnas])
				{
					suma = M_dev[threadIdx.x] * 2;
					//La casilla actual tendra el doble del valor
					M_dev[threadIdx.x] = M_dev[threadIdx.x] * 2;
					//La casilla posterior se pone a 0
					M_dev[threadIdx.x + p_num_columnas] = 0;
				}
			}
		}
		__syncthreads();
	}
	//Se repite el proceso para dejar el resultado sin 0 intermedios
	//Primero quitamos los 0 de la matriz para ello cada hilo ira subiendo los valores
	//de la matriz de abajo si no son 0 esto se hara varias veces hasta asegurarse de que este completo
	for (int i = 0; i < p_num_filas; i++) {
		//En caso de que el valor del hilo es 0 se mueve
		if ((M_dev[threadIdx.x] == 0)) {
			//Hay que asegurarse de no pasarse de rango de la columna
			if (threadIdx.x >= (p_num_columnas))
				//Si es distinto de 0 el valor anterior se procede a bajar
				if (!(M_dev[threadIdx.x + p_num_columnas] == 0)) {
					//Se reemplaza el valor de la casilla actual por el de despues
					M_dev[threadIdx.x] = M_dev[threadIdx.x + (p_num_columnas)];
					//Se deja la casilla posterior a 0 para que pueda ser ocupada por otros valores
					M_dev[threadIdx.x + (p_num_columnas)] = 0;
				}
		}
		//Sincronizamos los hilos para  asegurarnos de que acaban juntos
		__syncthreads();
	}
	//Para obtener la puntuacion nos aseguramos de cada hilo sume en orden la suma de puntos a la variable
	for (int i = 0; i < (p_num_columnas*p_num_filas); i++) {
		if (threadIdx.x == i) {
			*p_puntuacion_dev = *p_puntuacion_dev + suma;
		}
		//Hacemos que esperen a la ejecucion de la instruccion
		__syncthreads();
	}
}
__global__ void  moverIzquierda(int* M_dev, int p_num_columnas, int p_num_filas, int* p_puntuacion_dev) {
	//Obtendra la suma que se añadir a la puntuacion
	int suma = 0;
	//Movemos los valores distintos de 0 a la izquierda
	for (int i = 0; i < p_num_columnas; i++) {
		//En caso de que el valor del hilo es 0 se mueve
		if ((M_dev[threadIdx.x] == 0)) {
			//Si es distinto de 0 el valor anterior se procede a bajar siempre y cuando sea de la misma fila
			if (!(M_dev[threadIdx.x + 1] <= 0) && ((threadIdx.x + 1) < p_num_columnas*((threadIdx.x / p_num_columnas) + 1))) {
				//Se reemplaza el valor de la casilla actual por el de despues
				M_dev[threadIdx.x] = M_dev[threadIdx.x + 1];
				//Se deja la casilla posterior a 0 para que pueda ser ocupada por otros valores
				M_dev[threadIdx.x + 1] = 0;
			}
		}
		//Sincronizamos los hilos para  asegurarnos de que acaban juntos
		__syncthreads();
	}

	//Sumamos los numeros dejando 1 acceso al hilo por fila
	for (int k = 0; k < p_num_columnas; k++) {
		if ((threadIdx.x % p_num_columnas) == k) {
			//Si el valor es mayor o distinto de 0 se hace
			if (M_dev[threadIdx.x + 1] >= 0) {
				//Si los valores son iguales se suma
				if ((threadIdx.x + 1) < p_num_columnas*((threadIdx.x / p_num_columnas) + 1)) {


					if (M_dev[threadIdx.x] == M_dev[threadIdx.x + 1])
					{
						suma = M_dev[threadIdx.x] * 2;
						//Se suma a la casilla actual
						M_dev[threadIdx.x] = M_dev[threadIdx.x] * 2;
						//Se deja la posterior a 0
						M_dev[threadIdx.x + 1] = 0;
					}
				}
			}
		}
		//Sincronizamos los hilos
		__syncthreads();
	}
	//Volvemos a mover los 0 para dejar un resultado mas agradable
	//Movemos los valores distintos de 0 a la izquierda
	for (int i = 0; i < p_num_columnas; i++) {
		//En caso de que el valor del hilo es 0 se mueve
		if ((M_dev[threadIdx.x] == 0)) {
			//Si es distinto de 0 el valor anterior se procede a bajar siempre y cuando sea de la misma fila
			if (!(M_dev[threadIdx.x + 1] <= 0) && ((threadIdx.x + 1) < p_num_columnas*((threadIdx.x / p_num_columnas) + 1))) {
				//Se reemplaza el valor de la casilla actual por el de despues
				M_dev[threadIdx.x] = M_dev[threadIdx.x + 1];
				//Se deja la casilla posterior a 0 para que pueda ser ocupada por otros valores
				M_dev[threadIdx.x + 1] = 0;
			}
		}
		//Sincronizamos los hilos para  asegurarnos de que acaban juntos
		__syncthreads();
	}
	//Para obtener la puntuacion nos aseguramos de cada hilo sume en orden la suma de puntos a la variable
	for (int i = 0; i < (p_num_columnas*p_num_filas); i++) {
		if (threadIdx.x == i) {
			*p_puntuacion_dev = *p_puntuacion_dev + suma;
		}
		//Hacemos que esperen a la ejecucion de la instruccion
		__syncthreads();
	}
}
__global__ void  moverDerecha(int* M_dev, int p_num_columnas, int p_num_filas, int* p_puntuacion_dev) {
	//Obtendra la suma que se añadir a la puntuacion
	int suma = 0;
	//Movemos los valores distintos de 0 a la derecha
	for (int i = 0; i < p_num_columnas; i++) {
		//En caso de que el valor del hilo es 0 se mueve
		if ((M_dev[threadIdx.x] == 0)) {
			//Si es distinto de 0 el valor anterior se procede a bajar siempre y cuando sea de la misma fila
			if (threadIdx.x >= 1) {
				if (!(M_dev[threadIdx.x - 1] <= 0) && ((threadIdx.x - 1) >= p_num_columnas * ((threadIdx.x / p_num_columnas)))) {
					//Se reemplaza el valor de la casilla actual por el de despues
					M_dev[threadIdx.x] = M_dev[threadIdx.x - 1];
					//Se deja la casilla posterior a 0 para que pueda ser ocupada por otros valores
					M_dev[threadIdx.x - 1] = 0;
				}
			}
		}
		//Sincronizamos los hilos para  asegurarnos de que acaban juntos
		__syncthreads();
	}
	//Sumamos los numeros hacia la derecha
	//Para ello dejamos que cada hilo acceda a una unica fila
	for (int k = (p_num_columnas); k > 0; k--) {
		//Eso se consigue haciendo el resto
		if ((threadIdx.x % p_num_columnas) == k) {

			//Nos aseguramos de que este dentro de la matriz
			if (M_dev[threadIdx.x - 1] >= 0) {
				//Si son iguales procedemos a sumar
				if (M_dev[threadIdx.x] == M_dev[threadIdx.x - 1])
				{
					suma = M_dev[threadIdx.x] * 2;
					M_dev[threadIdx.x] = M_dev[threadIdx.x] * 2;
					M_dev[threadIdx.x - 1] = 0;
				}
			}
		}
		//Sincronizamos los hilos para  asegurarnos de que acaban juntos antes de empezar los siguientes
		__syncthreads();
	}	for (int i = 0; i < p_num_columnas; i++) {
		//En caso de que el valor del hilo es 0 se mueve
		if ((M_dev[threadIdx.x] == 0)) {
			//Si es distinto de 0 el valor anterior se procede a desplazar siempre y cuando sea de la misma fila
			if (threadIdx.x >= 1) {
				if (!(M_dev[threadIdx.x - 1] <= 0) && ((threadIdx.x - 1) >= p_num_columnas * ((threadIdx.x / p_num_columnas)))) {
					//Se reemplaza el valor de la casilla actual por el de antes
					M_dev[threadIdx.x] = M_dev[threadIdx.x - 1];
					//Se deja la casilla anterior a 0 para que pueda ser ocupada por otros valores
					M_dev[threadIdx.x - 1] = 0;
				}
			}
		}
		//Sincronizamos los hilos para  asegurarnos de que acaban juntos
		__syncthreads();
	}
	//Para obtener la puntuacion nos aseguramos de cada hilo sume en orden la suma de puntos a la variable
	for (int i = 0; i < (p_num_columnas*p_num_filas); i++) {
		if (threadIdx.x == i) {
			*p_puntuacion_dev = *p_puntuacion_dev + suma;
		}
		//Hacemos que esperen a la ejecucion de la instruccion
		__syncthreads();
	}
}
//Codigo main que lanzara el programa
int main(int argc, char** argv)
{
	//Ancho de la matriz (EJE X)
	int num_columnas = 3;
	//Alto de la matriz (EJE Y)
	int num_filas = 3;
	//Numero de semillas segun dificultad
	int SEMILLAS_ALTA = 8;
	int SEMILLAS_BAJA = 15;
	int* tablero;
	//Modo de dificultad
	bool dificultad = false;
	printf("¡Bienvenido al juego 16384!\n");
	//Si hay suficientes argumentos coge los valores pasados por consola
	if (argc > 3) {
		//Hacemos un cast a entero del valor de la consola
		dificultad = (2 == atoi(argv[2]));
		num_columnas = atoi(argv[3]);
		num_filas = atoi(argv[4]);
		tablero = inicializarMatriz(num_columnas, num_filas, dificultad, SEMILLAS_ALTA, SEMILLAS_BAJA);
		obtenerCaracteristicasCUDA(num_columnas, num_filas);
		getch();
		//Modo automatico y modo manual
		if (strcmp(argv[1], "-a") == 0) {
			modoAutomatico(tablero, num_columnas, num_filas, dificultad, SEMILLAS_ALTA, SEMILLAS_BAJA);
		}
		else if (strcmp(argv[1], "-m") == 0)
		{
			modoManual(tablero, num_columnas, num_filas, dificultad, SEMILLAS_ALTA, SEMILLAS_BAJA);
		}
		else {
			printf("El parametro que ha introducido %s no es valido\n", argv[1]);
		}
	}
	
	return 0;
}
/**
* Imprime un vector (que representa una matriz) como si fuera una matriz
*@param p_matriz_vector Vector que se mostrara por pantalla
*@param P_WIDTH_X Anchura de la matriz
*@param P_WIDTH_Y Altura de la matriz
*/
void imprimirMatrizVector(int* p_matriz_vector, int p_num_columnas, int p_num_filas) {
	//Bucle para imprimir las filas y colummnas
	for (int i = 0; i < p_num_filas; i++) {
		for (int j = 0; j < p_num_columnas; j++) {

			switch (p_matriz_vector[i * p_num_columnas + j]) {//	Modifica el color en el que se mostrarán los elementos
			case 0:
				Color(8, 8);
				break;
			case 2:
				Color(15, 0);
				break;
			case 4:
				Color(14, 0);
				break;
			case 8:
				Color(13, 0);
				break;
			case 16:
				Color(5, 15);
				break;
			case 32:
				Color(6, 0);
				break;
			case 64:
				Color(4, 0);
				break;
			case 128:
				Color(9, 0);
				break;
			case 256:
				Color(1, 0);
				break;
			case 512:
				Color(10, 0);
				break;
			case 1024:
				Color(2, 0);
				break;
			case 2048:
				Color(7, 0);
				break;
			case 4096:
				Color(8, 0);
				break;
			case 8192:
				Color(3, 0);
				break;
			case 16384:
				Color(15, 0);
				break;
			default:
				Color(0, 15);
				break;
			}
			printf("%d", p_matriz_vector[i * p_num_columnas + j]);
			printf("\t");
			Color(0,15);

		}

		printf("\n");

	}
	Color(0, 15);
}
/**
* Inicializa la matriz con multiplos de dos en funcion de la dificultad y semillas
* @param p_num_columnas Anchura de la matriz
* @param p_num_filas Altura de la matriz
* @param p_dificultad indica el modo de dificultad elegido
* @param p_semillas_alta numero de semillas que se crearan en nivel de juego alto
* @param p_semillas_baja numero de semillas que se crearan en nivel de juego bajo
*/
int* inicializarMatriz(int p_num_columnas, int p_num_filas, bool p_dificultad, int p_semillas_alta, int p_semillas_baja) {
	//Matriz que representa el tablero que se inicializa ademas se le asigna memoria
	int* tablero = (int *)malloc(p_num_columnas*p_num_filas * sizeof(int));
	//Numero de semillas que se generaran
	int numero_semillas = p_semillas_baja;
	//Vector con las posiciones de las semillas que contendran un valor inicial
	int* posicion_semillas;
	//Instante de tiempo que se usara para obtener numeros aleatorios
	srand((unsigned int)time(NULL));
	//Segun la dificultad generara unas semillas u otras
	// Si la dificultad es alta
	if (p_dificultad)
	{
		//Semillas que tendra la dificultad alta
		numero_semillas = p_semillas_alta;
		//Inicializamos el tablero
		for (int i = 0; i < p_num_filas; i++)
		{
			for (int j = 0; j < p_num_columnas; j++)
			{
				tablero[i * p_num_columnas + j] = 0;
			}
		}
		//Si hubiera mas semillas que casillas se llena hasta el maximo
		if (numero_semillas > (p_num_columnas*p_num_filas)) {
			numero_semillas = p_num_columnas * p_num_filas;
		}
		//Vector con los indices generados aleatoriamente donde iran los valores
		posicion_semillas = generaIndexSemilla(p_num_columnas, p_num_filas, numero_semillas);
		for (int i = 0; i < numero_semillas; i++)
		{
			//Se coloca en la posicion de la semilla el multiplo aleatorio de 2
			tablero[posicion_semillas[i]] = generarNumeros(p_dificultad);
		}
	}
	//Modo de dificultad baja
	else {
		for (int i = 0; i < p_num_filas; i++)
		{
			for (int j = 0; j < p_num_columnas; j++)
			{
				tablero[i * p_num_columnas + j] = 0;
			}
		}
		//Si hubiera mas semillas que casillas se llena hasta el maximo
		if (numero_semillas > (p_num_columnas*p_num_filas)) {
			numero_semillas = p_num_columnas * p_num_filas;
		}
		//Vector con los indices generados aleatoriamente donde iran los valores
		posicion_semillas = generaIndexSemilla(p_num_columnas, p_num_filas, numero_semillas);
		for (int i = 0; i < numero_semillas; i++)
		{
			//Se coloca en la posicion de la semilla el multiplo aleatorio de 2
			tablero[posicion_semillas[i]] = generarNumeros(p_dificultad);
		}
	}
	//Finalmente devolvemos el tablero
	return tablero;
}
/**
* Funcion que genera multiplos de dos segun la dificultad
*@param dificultad booleano que indica la dificultad del juego
*/
int generarNumeros(bool dificultad) {
	int valoresBajos []= { 2,4,8 };
	int valoresAltos[] = { 2,4};
	//Siempre genera multiplos entre 2, 4 y 8
	int num = valoresBajos[rand() % 3];
	//Si la dificultad es alta los genera entre 2,4
	if (dificultad)
	{
		num = valoresAltos[rand() % 2];
	}
	//Devuelve el multiplo generado
	return num;
}
/**
* Genera un vector con los indices de las semillas para las casillas de la matriz
* @param p_num_columnas columnas de la matriz
* @param p_num_filas filas de la matriz
* @param p_tam tamano del vector a generar
*/
int* generaIndexSemilla(int p_num_columnas, int p_num_filas, int p_tam) {
	//Vector con los indices de las semillas del tamano dado
	int* indexes = (int *)malloc(p_tam * sizeof(int));
	//Primer indice
	int index = rand() % p_num_columnas*p_num_filas;
	//Contador que usaremos en el bucle
	int cont = 0;
	while (cont != p_tam)
	{
		//Si el valor generado no esta se introduce y se busca el siguiente
		if (!contiene(index, indexes, p_tam))
		{
			indexes[cont] = index;
			cont++;
		}
		//Nuevo indice a probar
		index = rand() % (p_num_columnas*p_num_filas);
	}
	//Devuelve los indices de las semillas generadas para la matriz
	return indexes;
}
/**
* Rellena la matriz con multiplos de dos en funcion de la dificultad, semillas y huecos libres
* @param p_tablero tablero que se rellenara con las semillas
* @param p_num_columnas Anchura de la matriz
* @param p_num_filas Altura de la matriz
* @param p_dificultad indica el modo de dificultad elegido
* @param p_semillas_alta numero de semillas que se crearan en nivel de juego alto
* @param p_semillas_baja numero de semillas que se crearan en nivel de juego bajo
*/
int* rellenarTablero(int* p_tablero, int p_num_columnas, int p_num_filas, bool p_dificultad, int p_semillas_alta, int p_semillas_baja, bool* p_lleno) {
	//Huecos disponibles en la matriz
	int huecos = comprobarCasillasVacias(p_tablero, p_num_columnas, p_num_filas);
	//Cantidad de semillas a meter
	int semillas = p_semillas_baja;
	//Indice que se probara
	int index = rand() % (p_num_columnas*p_num_filas);
	//Si es dificil la cantidad cambia
	if (p_dificultad) {
		semillas = p_semillas_alta;
	}
	//Si hay mas huecos que semillas se introducen todas las semillas
	if (semillas < huecos) {
		*p_lleno = false;
		//Mientras tengamos semillas se van buscando posiciones aleatoriamente
		while (semillas > 0) {
			index = rand() % (p_num_columnas*p_num_filas);
			//Se comprueba que este a 0 el hueco
			if (p_tablero[index] == 0) {
				//Se introduce y se reducen las semillas
				p_tablero[index] = generarNumeros(p_dificultad);
				semillas--;
			}
		}
	}
	//Si hay mas semillas que huecos se adaptan
	else {
		*p_lleno = true;
		//Si hay huecos se rellenan si no se acaba
		if (huecos != 0) {
			semillas = huecos;
			//Mientras las nuevas semillas sean mayores que 0 se rellena
			while (semillas > 0) {
				index = rand() % (p_num_columnas*p_num_filas);
				if (p_tablero[index] == 0) {
					p_tablero[index] = generarNumeros(p_dificultad);
					semillas--;
				}
			}
		}
	}
	//Devolvemos el tablero relleno
	return p_tablero;
}

/**
* Comprueba si un valor se encuentra en el vector
* @param p_valor valor que se quiere encontrar
* @param semillas vector donde se buscará
* @param p_tam tamano del vector que hay para buscar
* @return Booleano que indica si esta contenido
*/
bool contiene(int p_valor, int* semillas, int p_tam) {
	//Se incializa el valor por defecto a false
	bool estaContenido = false;
	//Recorremos el vector para comprobar si se encuentra
	for (int i = 0; i < p_tam; i++)
	{
		//Si lo encuentra se para la ejecucion y devuelve true
		if (semillas[i] == p_valor)
		{
			estaContenido = true;
			break;
		}
	}
	//Devuelve el booleano que indica si se contiene
	return estaContenido;
}
/**
* Modalidad de juego en la que funciona automaticamente de forma aleatoria
* @param p_tablero matriz en la que se jugara
* @param p_num_columnas Anchura de la matriz
* @param p_num_filas Altura de la matriz
* @param p_dificultad booleano que indica la dificultad del juego
* @param p_semillas_baja cantidad de semillas que se generan en dificultad baja
* @param p_semillas_alta cantidad de semillas que se generan en dificultad alta
*/
void modoAutomatico(int* p_tablero, int p_num_columnas, int p_num_filas, bool p_dificultad, int p_semillas_baja, int p_semillas_alta)
{
	//Variable para el tamaño
	int size = p_num_columnas * p_num_filas;
	//Semilla que se usara para aleatorizar los numeros aleatorios
	srand((unsigned int)time(NULL));
	int record = cargarRecord();
	int vidas = 5;
	//Cuenta los movimientos que se han hecho
	int cont = 0;
	int puntuacion = 0;
	char tecla;
	int puntuacion_anterior = 0;
	int* puntuacion_dev = 0;
	bool lleno = false;
	bool bloqueoEjeX = false;
	bool bloqueoEjeY = false;
	//Movimiento que se realizara
	int movimiento;
	//Definimos el tablero que habrá en la grafica
	int* tablero_dev;
	//Declaramos la dimension de CUDA
	dim3 dimBlock(p_num_columnas*p_num_filas);
	//Reservamos memoria global en la grafica
	cudaMalloc((void**)&tablero_dev, size * sizeof(int));
	cudaMalloc((void**)&puntuacion_dev, sizeof(int));
	do {
		//Guardamos la puntuacion anterior para calculos
		puntuacion_anterior = puntuacion;
		//Tiempo de espera para poder apreciar los movimientos
		Sleep(400);
		//Movimiento aleatorio que se crea
		movimiento = rand() % 4;

		//Se limpia la pantalla y se muestra la matriz
		system("cls");
		printf("    ---.::: 16384 - THE GAME :::.---\n\n");
		printf("*************************************\n");
		imprimirMatrizVector(p_tablero, p_num_columnas, p_num_filas);
		printf("*************************************\n");
		printf("Movimiento numero: %d\n", cont);
		printf("Puntuacion: %d\t", puntuacion);
		printf("Record: %d\n", record);
		//Si las vidas llegan a 0 se acaba el juego
		if (vidas < 0) {
			system("cls");
			printf("\n\t-Te has quedado sin vidas-\n");
			printf("\n\t-Has perdido la partida-\n");
			getch();
			//Liberamos la memoria que se emplea en cuda
			cudaFree(tablero_dev);
			cudaFree(puntuacion_dev);
			if (record < puntuacion) {
				system("cls");
				printf("\n______________________________________________________________________");
				printf("\n -:: Enhorabuena has superado el record guardaremos esta puntuacion ::-");
				printf("\n\n\t\t\t NUEVO RECORD: %d", puntuacion);
				printf("\n\t\t\t ANTERIOR RECORD: %d", record);
				printf("\n______________________________________________________________________\n");
				guardarRecord(puntuacion);
			}
			exit(0);
		}

		//Mostramos las vidas con colores y en funcion de las que quedan
		printf("Vidas: ");
		Color(0, 12);
		for (int i = 0; i < vidas; i++) {
			printf("<3 ");
		}
		Color(0, 15);

		//Segun el valor realiza un movimiento u otro
		switch (movimiento)
		{
			//Movimiento hacia arriba - W
		case 0: printf("\n Direccion: Arriba\n");
			//Se pasa a memoria de la grafica el tablero
			cudaMemcpy(tablero_dev, p_tablero, size * sizeof(int), cudaMemcpyHostToDevice);
			//Se realiza el calculo en el kernel
			moverArriba << <1, dimBlock >> > (tablero_dev, p_num_columnas, p_num_filas, puntuacion_dev);
			//Se devuelve el resultado
			cudaMemcpy(p_tablero, tablero_dev, size * sizeof(int), cudaMemcpyDeviceToHost);
			//Obtenemos la puntuacion despues del movimiento
			cudaMemcpy(&puntuacion, puntuacion_dev, sizeof(int), cudaMemcpyDeviceToHost);
			//Despues de realizar el movimiento se rellena con valores
			p_tablero = rellenarTablero(p_tablero, p_num_columnas, p_num_filas, p_dificultad, p_semillas_alta, p_semillas_baja, &lleno);
			break;
			//Movimiento hacia la izquierda - A
		case 1: printf("\n Direccion: Izquierda\n");
			cudaMemcpy(tablero_dev, p_tablero, size * sizeof(int), cudaMemcpyHostToDevice);
			moverIzquierda << <1, dimBlock >> > (tablero_dev, p_num_columnas, p_num_filas, puntuacion_dev);
			cudaMemcpy(p_tablero, tablero_dev, size * sizeof(int), cudaMemcpyDeviceToHost);
			//Obtenemos la puntuacion despues del movimiento
			cudaMemcpy(&puntuacion, puntuacion_dev, sizeof(int), cudaMemcpyDeviceToHost);
			//Despues de realizar el movimiento se rellena con valores
			p_tablero = rellenarTablero(p_tablero, p_num_columnas, p_num_filas, p_dificultad, p_semillas_alta, p_semillas_baja, &lleno);
			break;
			//Movimiento hacia abajo- S
		case 2: printf("\n Direccion: Abajo\n");
			cudaMemcpy(tablero_dev, p_tablero, size * sizeof(int), cudaMemcpyHostToDevice);
			moverAbajo << <1, dimBlock >> > (tablero_dev, p_num_columnas, p_num_filas, puntuacion_dev);
			cudaMemcpy(p_tablero, tablero_dev, size * sizeof(int), cudaMemcpyDeviceToHost);
			//Obtenemos la puntuacion despues del movimiento
			cudaMemcpy(&puntuacion, puntuacion_dev, sizeof(int), cudaMemcpyDeviceToHost);
			//Despues de realizar el movimiento se rellena con valores
			p_tablero = rellenarTablero(p_tablero, p_num_columnas, p_num_filas, p_dificultad, p_semillas_alta, p_semillas_baja, &lleno);
			break;
			//Movimiento hacia la derecha- D
		case 3: printf("\n Direccion: Derecha\n");
			cudaMemcpy(tablero_dev, p_tablero, size * sizeof(int), cudaMemcpyHostToDevice);
			moverDerecha << <1, dimBlock >> > (tablero_dev, p_num_columnas, p_num_filas, puntuacion_dev);
			cudaMemcpy(p_tablero, tablero_dev, size * sizeof(int), cudaMemcpyDeviceToHost);
			//Obtenemos la puntuacion despues del movimiento
			cudaMemcpy(&puntuacion, puntuacion_dev, sizeof(int), cudaMemcpyDeviceToHost);
			//Despues de realizar el movimiento se rellena con valores
			p_tablero = rellenarTablero(p_tablero, p_num_columnas, p_num_filas, p_dificultad, p_semillas_alta, p_semillas_baja, &lleno);
			break;
		default:
			break;
		}
		p_tablero = rellenarTablero(p_tablero, p_num_columnas, p_num_filas, p_dificultad, p_semillas_alta, p_semillas_baja, &lleno);
		cont++;

		//---------------------------------COMPROBACION DE BLOQUEO DEL JUEGO----------------------------------------
		//Solo se comprueba cuando esta lleno el tablero para ahorrar costes
		if (lleno)
		{
			//Para comprobar si no se pueden hacer movimientos se comprueban los cambios de puntuaciones
			//Si esta no varia al tener el tablero lleno significa que en ese eje no quedan mas movimientos
			if (puntuacion_anterior == puntuacion)
			{
				//Detectamos el eje en el que no se pueden hacer mas movimientos
				if (movimiento == 0 || movimiento == 2)
				{
					//Se bloquea el eje Y 
					bloqueoEjeY = true;
				}
				else if (movimiento == 1 || movimiento == 3)
				{
					//Se bloquea el eje X
					bloqueoEjeX = true;
				}
			}
			//Si las puntuaciones difieren aunque este lleno el tablero significa que aun hay movimientos
			else {
				//Se desbloquean los dos ejes
				bloqueoEjeX = false;
				bloqueoEjeY = false;
			}

		}
		//Si no esta lleno significa que hay huecos para hacer movimientos
		else {
			//Se desbloquean los dos ejes
			bloqueoEjeX = false;
			bloqueoEjeY = false;
		}
		//Si se bloquean los dos ejes simultaneamente el juego se bloquea
		if (bloqueoEjeX && bloqueoEjeY)
		{
			//Desbloqueamos ejes por si se quiere continuar jugando 
			bloqueoEjeX = false;
			bloqueoEjeY = false;
			//Se muestran los mensajes
			printf("\nHAS PERDIDO\n");
			printf("¿Quieres volver a jugar? (Pulsa y para jugar)\n");
			//Obtenemos la respuesta
			scanf(" %c", &tecla);
			//Si responde afirmativamente se quita un vida y se reinicia el tablero
			if (tecla == 'y' || tecla == 'Y')
			{
				vidas--;
				p_tablero = inicializarMatriz(p_num_columnas, p_num_filas, p_dificultad, p_semillas_alta, p_semillas_baja);
			}
			//Si no quiere jugar se le pregunta si desea guardar la partida para continuarla despues
			else {
				printf("¿Desea guardar la partida? (Pulsa y para guardar)\n");
				//Obtenemos la respuesta
				scanf(" %c", &tecla);
				//Si responde afirmativamente se guardan los datos y se sale
				if (tecla == 'y' || tecla == 'Y')
				{
					guardarPartida(p_tablero, vidas, puntuacion, p_num_columnas, p_num_filas);
					printf("¡Se han guardado los datos correctamente!\n");
				}
				printf("Saliendo...");
				//Liberamos la memoria que se emplea en cuda
				cudaFree(tablero_dev);
				cudaFree(puntuacion_dev);
				//Codigo de exito 0
				if (record < puntuacion) {
					system("cls");
					printf("\n______________________________________________________________________");
					printf("\n -:: Enhorabuena has superado el record guardaremos esta puntuacion ::-");
					printf("\n\n\t\t\t NUEVO RECORD: %d", puntuacion);
					printf("\n\t\t\t ANTERIOR RECORD: %d", record);
					printf("\n______________________________________________________________________\n");
					guardarRecord(puntuacion);
				}
				exit(0);
			}

		}
	} while (true);
}
/**
* Modalidad de juego en la que funciona manualmente 
* @param p_tablero matriz en la que se jugara
* @param p_num_columnas Anchura de la matriz
* @param p_num_filas Altura de la matriz
* @param p_dificultad booleano que indica la dificultad del juego
* @param p_semillas_baja cantidad de semillas que se generan en dificultad baja
* @param p_semillas_alta cantidad de semillas que se generan en dificultad alta
*/
void modoManual(int* p_tablero, int p_num_columnas, int p_num_filas, bool p_dificultad, int p_semillas_baja, int p_semillas_alta)
{

	//Declaracion e inicializacion de variables
	int record = cargarRecord();
	int vidas = 5;
	int size = p_num_columnas * p_num_filas;
	int puntuacion = 0;
	char tecla;
	int puntuacion_anterior = 0;
	//Booleanos empleados en el control del bloqueo del juego
	bool bloqueoEjeX = false;
	bool bloqueoEjeY = false;
	bool lleno = false;
	//-------------------------------CARGA DE PARTIDA----------------------------------------
	//Limpiamos la pantalla
	system("cls");
	//Preguntamos si desea cargar una partida
	printf("Desea cargar partida?(Pulse y para cargar partida)\n");
	tecla = getch();
	//Si responde afirmativamente se reemplazan los valores por los almacenados
	if (tecla == 'y') {
		p_tablero = cargarPartida(&vidas, &puntuacion, &p_num_columnas, &p_num_filas);
		//Se actualiza el tamaño a reservar
		size = p_num_columnas * p_num_filas;
	}
	//--------------------------Declaracion y reserva para CUDA------------------------------

	//Definimos el tablero que habrá en la grafica
	int* puntuacion_dev = 0;
	int* tablero_dev;
	//Declaramos la dimension de CUDA
	dim3 dimBlock(p_num_columnas*p_num_filas);
	//Reservamos memoria global en la grafica
	cudaMalloc((void**)&tablero_dev, size * sizeof(int));
	cudaMalloc((void**)&puntuacion_dev, sizeof(int));
	//--------------------------- BUCLE DEL JUEGO---------------------------------------
	do {
		//Guardamos la puntuacion anterior para calculos
		puntuacion_anterior = puntuacion;

		//Mostramos los datos por pantalla
		system("cls");
		printf("    ---.::: 16384 - THE GAME :::.---\n\n");
		printf("==============================================\n");
		imprimirMatrizVector(p_tablero, p_num_columnas, p_num_filas);
		printf("==============================================\n");
		printf("Puntuacion: %d\t", puntuacion);
		printf("Record: %d\n", record);

		//Si las vidas son menores a 0 se acaba el juego
		if (vidas < 0) {
			printf("\n\t-Te has quedado sin vidas-\n");
			printf("\n\t-Has perdido la partida-\n");
			getch();
			//Liberamos la memoria que se emplea en cuda
			cudaFree(tablero_dev);
			cudaFree(puntuacion_dev);
			if (record < puntuacion) {
				printf("\n -Enhorabuena has superado el record guardaremos esta puntuacion-");
				guardarRecord(puntuacion);
			}
			exit(0);
		}
		//Mostramos las vidas con colores y segun cantidad
		printf("Vidas: ");
		Color(0, 12);
		for (int i = 0; i < vidas; i++) {
			printf("<3 ");
		}
		Color(0, 15);

		//Solicitamos un movimiento
		tecla = getch();
		//En el caso de las flechas para evitar errores se solicita 2 veces
		if (tecla == -32) {
			tecla = getch();
		}
		switch (tecla)
		{
			//Movimiento hacia arriba - W
		case 'w':
			//Se pasa a memoria de la grafica el tablero
			cudaMemcpy(tablero_dev, p_tablero, size * sizeof(int), cudaMemcpyHostToDevice);
			//Se realiza el calculo en el kernel
			moverArriba << <1, dimBlock >> > (tablero_dev, p_num_columnas, p_num_filas, puntuacion_dev);
			//Se devuelve el resultado
			cudaMemcpy(p_tablero, tablero_dev, size * sizeof(int), cudaMemcpyDeviceToHost);
			//Obtenemos la puntuacion despues del movimiento
			cudaMemcpy(&puntuacion, puntuacion_dev, sizeof(int), cudaMemcpyDeviceToHost);
			//Despues de realizar el movimiento se rellena con valores
			p_tablero = rellenarTablero(p_tablero, p_num_columnas, p_num_filas, p_dificultad, p_semillas_alta, p_semillas_baja, &lleno);
			break;
		case 'W':
			//Se pasa a memoria de la grafica el tablero
			cudaMemcpy(tablero_dev, p_tablero, size * sizeof(int), cudaMemcpyHostToDevice);
			//Se realiza el calculo en el kernel
			moverArriba << <1, dimBlock >> > (tablero_dev, p_num_columnas, p_num_filas, puntuacion_dev);
			//Se devuelve el resultado
			cudaMemcpy(p_tablero, tablero_dev, size * sizeof(int), cudaMemcpyDeviceToHost);
			//Obtenemos la puntuacion despues del movimiento
			cudaMemcpy(&puntuacion, puntuacion_dev, sizeof(int), cudaMemcpyDeviceToHost);
			//Despues de realizar el movimiento se rellena con valores
			p_tablero = rellenarTablero(p_tablero, p_num_columnas, p_num_filas, p_dificultad, p_semillas_alta, p_semillas_baja, &lleno);
			break;
			//Se corresponde con la flecha del teclado
		case 72:
			cudaMemcpy(tablero_dev, p_tablero, size * sizeof(int), cudaMemcpyHostToDevice);
			moverArriba << <1, dimBlock >> > (tablero_dev, p_num_columnas, p_num_filas, puntuacion_dev);
			cudaMemcpy(p_tablero, tablero_dev, size * sizeof(int), cudaMemcpyDeviceToHost);
			//Obtenemos la puntuacion despues del movimiento
			cudaMemcpy(&puntuacion, puntuacion_dev, sizeof(int), cudaMemcpyDeviceToHost);
			p_tablero = rellenarTablero(p_tablero, p_num_columnas, p_num_filas, p_dificultad, p_semillas_alta, p_semillas_baja, &lleno);
			break;
			//Movimiento hacia la izquierda - A
		case 'a':
			cudaMemcpy(tablero_dev, p_tablero, size * sizeof(int), cudaMemcpyHostToDevice);
			moverIzquierda << <1, dimBlock >> > (tablero_dev, p_num_columnas, p_num_filas, puntuacion_dev);
			cudaMemcpy(p_tablero, tablero_dev, size * sizeof(int), cudaMemcpyDeviceToHost);
			//Obtenemos la puntuacion despues del movimiento
			cudaMemcpy(&puntuacion, puntuacion_dev, sizeof(int), cudaMemcpyDeviceToHost);
			p_tablero = rellenarTablero(p_tablero, p_num_columnas, p_num_filas, p_dificultad, p_semillas_alta, p_semillas_baja, &lleno);
			break;
		case 'A':
			cudaMemcpy(tablero_dev, p_tablero, size * sizeof(int), cudaMemcpyHostToDevice);
			moverIzquierda << <1, dimBlock >> > (tablero_dev, p_num_columnas, p_num_filas, puntuacion_dev);
			cudaMemcpy(p_tablero, tablero_dev, size * sizeof(int), cudaMemcpyDeviceToHost);
			//Obtenemos la puntuacion despues del movimiento
			cudaMemcpy(&puntuacion, puntuacion_dev, sizeof(int), cudaMemcpyDeviceToHost);
			p_tablero = rellenarTablero(p_tablero, p_num_columnas, p_num_filas, p_dificultad, p_semillas_alta, p_semillas_baja, &lleno);
			break;
			//Se corresponde con la flecha del teclado
		case 75:
			cudaMemcpy(tablero_dev, p_tablero, size * sizeof(int), cudaMemcpyHostToDevice);
			moverIzquierda << <1, dimBlock >> > (tablero_dev, p_num_columnas, p_num_filas, puntuacion_dev);
			cudaMemcpy(p_tablero, tablero_dev, size * sizeof(int), cudaMemcpyDeviceToHost);
			//Obtenemos la puntuacion despues del movimiento
			cudaMemcpy(&puntuacion, puntuacion_dev, sizeof(int), cudaMemcpyDeviceToHost);
			p_tablero = rellenarTablero(p_tablero, p_num_columnas, p_num_filas, p_dificultad, p_semillas_alta, p_semillas_baja, &lleno);
			break;
			//Movimiento hacia abajo- S
		case 's':
			cudaMemcpy(tablero_dev, p_tablero, size * sizeof(int), cudaMemcpyHostToDevice);
			moverAbajo << <1, dimBlock >> > (tablero_dev, p_num_columnas, p_num_filas, puntuacion_dev);
			cudaMemcpy(p_tablero, tablero_dev, size * sizeof(int), cudaMemcpyDeviceToHost);
			//Obtenemos la puntuacion despues del movimiento
			cudaMemcpy(&puntuacion, puntuacion_dev, sizeof(int), cudaMemcpyDeviceToHost);
			p_tablero = rellenarTablero(p_tablero, p_num_columnas, p_num_filas, p_dificultad, p_semillas_alta, p_semillas_baja, &lleno);
			break;
		case 'S':
			cudaMemcpy(tablero_dev, p_tablero, size * sizeof(int), cudaMemcpyHostToDevice);
			moverAbajo << <1, dimBlock >> > (tablero_dev, p_num_columnas, p_num_filas, puntuacion_dev);
			cudaMemcpy(p_tablero, tablero_dev, size * sizeof(int), cudaMemcpyDeviceToHost);
			//Obtenemos la puntuacion despues del movimiento
			cudaMemcpy(&puntuacion, puntuacion_dev, sizeof(int), cudaMemcpyDeviceToHost);
			p_tablero = rellenarTablero(p_tablero, p_num_columnas, p_num_filas, p_dificultad, p_semillas_alta, p_semillas_baja, &lleno);
			break;
			//Se corresponde con la flecha del teclado
		case 80:
			cudaMemcpy(tablero_dev, p_tablero, size * sizeof(int), cudaMemcpyHostToDevice);
			moverAbajo << <1, dimBlock >> > (tablero_dev, p_num_columnas, p_num_filas, puntuacion_dev);
			cudaMemcpy(p_tablero, tablero_dev, size * sizeof(int), cudaMemcpyDeviceToHost);
			//Obtenemos la puntuacion despues del movimiento
			cudaMemcpy(&puntuacion, puntuacion_dev, sizeof(int), cudaMemcpyDeviceToHost);
			p_tablero = rellenarTablero(p_tablero, p_num_columnas, p_num_filas, p_dificultad, p_semillas_alta, p_semillas_baja, &lleno);
			break;
			//Movimiento hacia la derecha- D
		case 'd':
			cudaMemcpy(tablero_dev, p_tablero, size * sizeof(int), cudaMemcpyHostToDevice);
			moverDerecha << <1, dimBlock >> > (tablero_dev, p_num_columnas, p_num_filas, puntuacion_dev);
			cudaMemcpy(p_tablero, tablero_dev, size * sizeof(int), cudaMemcpyDeviceToHost);
			//Obtenemos la puntuacion despues del movimiento
			cudaMemcpy(&puntuacion, puntuacion_dev, sizeof(int), cudaMemcpyDeviceToHost);
			p_tablero = rellenarTablero(p_tablero, p_num_columnas, p_num_filas, p_dificultad, p_semillas_alta, p_semillas_baja, &lleno);
			break;
		case 'D':
			cudaMemcpy(tablero_dev, p_tablero, size * sizeof(int), cudaMemcpyHostToDevice);
			moverDerecha << <1, dimBlock >> > (tablero_dev, p_num_columnas, p_num_filas, puntuacion_dev);
			cudaMemcpy(p_tablero, tablero_dev, size * sizeof(int), cudaMemcpyDeviceToHost);
			//Obtenemos la puntuacion despues del movimiento
			cudaMemcpy(&puntuacion, puntuacion_dev, sizeof(int), cudaMemcpyDeviceToHost);
			p_tablero = rellenarTablero(p_tablero, p_num_columnas, p_num_filas, p_dificultad, p_semillas_alta, p_semillas_baja, &lleno);
			break;
			//Se corresponde con la flecha del teclado
		case 77:
			cudaMemcpy(tablero_dev, p_tablero, size * sizeof(int), cudaMemcpyHostToDevice);
			moverDerecha << <1, dimBlock >> > (tablero_dev, p_num_columnas, p_num_filas, puntuacion_dev);
			cudaMemcpy(p_tablero, tablero_dev, size * sizeof(int), cudaMemcpyDeviceToHost);
			//Obtenemos la puntuacion despues del movimiento
			cudaMemcpy(&puntuacion, puntuacion_dev, sizeof(int), cudaMemcpyDeviceToHost);
			p_tablero = rellenarTablero(p_tablero, p_num_columnas, p_num_filas, p_dificultad, p_semillas_alta, p_semillas_baja, &lleno);
			break;
			//Guardamos los datos de la partida
		case 'g': printf("Guardando partida...\n");
			guardarPartida(p_tablero, vidas, puntuacion, p_num_columnas, p_num_filas);
			break;
		case 'G': printf("Guardando partida...\n");
			guardarPartida(p_tablero, vidas, puntuacion, p_num_columnas, p_num_filas);
			break;
			//Se sale del juego
		case 'e': printf("Saliendo ...\n");
			//Liberamos la memoria que se emplea
			cudaFree(tablero_dev);
			cudaFree(puntuacion_dev);
			if (record < puntuacion) {
				system("cls");
				printf("\n______________________________________________________________________");
				printf("\n -:: Enhorabuena has superado el record guardaremos esta puntuacion ::-");
				printf("\n\n\t\t\t NUEVO RECORD: %d", puntuacion);
				printf("\n\t\t\t ANTERIOR RECORD: %d", record);
				printf("\n______________________________________________________________________\n");
				guardarRecord(puntuacion);
			}
			exit(0);
			break;
		case 'E': printf("Saliendo ...\n");
			//Liberamos la memoria que se emplea
			cudaFree(tablero_dev);
			cudaFree(puntuacion_dev);
			if (record < puntuacion) {
				system("cls");
				printf("\n______________________________________________________________________");
				printf("\n -:: Enhorabuena has superado el record guardaremos esta puntuacion ::-");
				printf("\n\n\t\t\t NUEVO RECORD: %d", puntuacion);
				printf("\n\t\t\t ANTERIOR RECORD: %d", record);
				printf("\n______________________________________________________________________\n");
				guardarRecord(puntuacion);
			}
			exit(0);
			break;
		default:
			break;
		}

		//---------------------------------COMPROBACION DE BLOQUEO DEL JUEGO----------------------------------------
		//Solo se comprueba cuando esta lleno el tablero para ahorrar costes
		if (lleno)
		{
			//Para comprobar si no se pueden hacer movimientos se comprueban los cambios de puntuaciones
			//Si esta no varia al tener el tablero lleno significa que en ese eje no quedan mas movimientos
			if (puntuacion_anterior == puntuacion)
			{
				//Detectamos el eje en el que no se pueden hacer mas movimientos
				if (tecla == 'w' || tecla == 's' || tecla == 'W' || tecla == 'S' || tecla == 72 || tecla == 80)
				{
					//Se bloquea el eje Y 
					bloqueoEjeY = true;
				}
				else if (tecla == 'a' || tecla == 'd' || tecla == 'A' || tecla == 'D' || tecla == 77 || tecla == 75)
				{
					//Se bloquea el eje X
					bloqueoEjeX = true;
				}
			}
			//Si las puntuaciones difieren aunque este lleno el tablero significa que aun hay movimientos
			else {
				//Se desbloquean los dos ejes
				bloqueoEjeX = false;
				bloqueoEjeY = false;
			}

		}
		//Si no esta lleno significa que hay huecos para hacer movimientos
		else {
			//Se desbloquean los dos ejes
			bloqueoEjeX = false;
			bloqueoEjeY = false;
		}
		//Si se bloquean los dos ejes simultaneamente el juego se bloquea
		if (bloqueoEjeX && bloqueoEjeY)
		{
			//Desbloqueamos ejes por si se quiere continuar jugando 
			bloqueoEjeX = false;
			bloqueoEjeY = false;
			//Se muestran los mensajes
			printf("\nHAS PERDIDO\n");
			printf("¿Quieres volver a jugar? (Pulsa y para jugar)\n");
			//Obtenemos la respuesta
			scanf(" %c", &tecla);
			//Si responde afirmativamente se quita un vida y se reinicia el tablero
			if (tecla == 'y' || tecla == 'Y')
			{
				vidas--;
				p_tablero = inicializarMatriz(p_num_columnas, p_num_filas, p_dificultad, p_semillas_alta, p_semillas_baja);
			}
			//Si no quiere jugar se le pregunta si desea guardar la partida para continuarla despues
			else {
				printf("¿Desea guardar la partida? (Pulsa y para guardar)\n");
				//Obtenemos la respuesta
				scanf(" %c", &tecla);
				//Si responde afirmativamente se guardan los datos y se sale
				if (tecla == 'y' || tecla == 'Y')
				{
					guardarPartida(p_tablero, vidas, puntuacion, p_num_columnas, p_num_filas);
					printf("¡Se han guardado los datos correctamente!\n");
				}
				printf("Saliendo...");
				//Liberamos la memoria que se emplea en cuda
				cudaFree(tablero_dev);
				cudaFree(puntuacion_dev);
				//Codigo de exito 0
				if (record < puntuacion) {
					system("cls");
					printf("\n______________________________________________________________________");
					printf("\n -:: Enhorabuena has superado el record guardaremos esta puntuacion ::-");
					printf("\n\n\t\t\t NUEVO RECORD: %d", puntuacion);
					printf("\n\t\t\t ANTERIOR RECORD: %d", record);
					printf("\n______________________________________________________________________\n");
					guardarRecord(puntuacion);
				}
				exit(0);
			}

		}
	} while (true);
}

//--------------------------------CARGAR Y GUARDAR PARTIDAS--------------------------------------

/**
* Guarda el estado de la partida con su tablero y datos
* @param p_tablero guarda la matriz completa
* @param p_vidas numero de vidas disponibles
* @param p_puntuacion puntuacion que se tenia en el momento del guardado
* @param p_num_columnas Anchura de la matriz
* @param p_num_filas Altura de la matriz
*/
void guardarPartida(int* p_tablero, int p_vidas, int p_puntuacion, int p_num_columnas, int p_num_filas) {
	FILE *archivo;
	//Se abre/crea el archivo para escribir
	archivo = fopen("datos_partida.txt", "w");
	//En caso de que se haya hecho bien se procede al guardado
	if (archivo != NULL) {
		//Guardamos cada variable, y la matriz la escribimos completa
		fprintf(archivo, "%i \n", p_vidas);
		fprintf(archivo, "%i \n", p_puntuacion);
		fprintf(archivo, "%i \n", p_num_columnas);
		fprintf(archivo, "%i \n", p_num_filas);
		for (int i = 0; i < (p_num_columnas*p_num_filas); i++) {
			fprintf(archivo, "%i ", p_tablero[i]);
		}
		//Cerramos el archivo
		fclose(archivo);
		printf("Guardado realizado con exito.\n");
	}
	//Si se ha creado mal se muestra un mensaje
	else {
		printf("No se ha podido abrir/crear el archivo\n");
		exit(-1);
	}
}
/**
* Carga el estado de la partida con su tablero y datos mediante punteros
* @param p_vidas numero de vidas disponibles
* @param p_puntuacion puntuacion que se tenia en el momento del guardado
* @param p_num_columnas Anchura de la matriz
* @param p_num_filas Altura de la matriz
* @return devuelve el tablero
*/
int* cargarPartida(int* p_vidas, int* p_puntuacion, int* p_num_columnas, int* p_num_filas) {
	//Declaramos variables
	int* tablero;
	FILE *archivo;
	//Indicamos el archivo a leer
	archivo = fopen("datos_partida.txt", "r");
	//Leera los datos solo si se ha abierto bien el archivo
	if (archivo != NULL) {
		//Se leen las variables y la matriz a partir de sus variables
		fscanf(archivo, "%i", p_vidas);
		fscanf(archivo, "%i", p_puntuacion);
		fscanf(archivo, "%i", p_num_columnas);
		fscanf(archivo, "%i", p_num_filas);
		//Inicializamos la matriz tablero
		tablero = (int *)malloc((*p_num_columnas)*(*p_num_filas) * sizeof(int));
		//Recomponemos la matriz tablero a partir de los elementos
		for (int i = 0; i < (*p_num_columnas)*(*p_num_filas); i++) {
			fscanf(archivo, "%i", &tablero[i]);
		}
		//Cerramos el archivo
		fclose(archivo);
		printf("Partida cargada con exito.\n");
	}
	else {
		printf("No se ha podido leer el archivo, es posible que no haya ninguna guardada\n");
		exit(-1);
	}
	//Se devuelve el tablero finalmente
	return tablero;
}
/**
* Guarda la puntuacion record
* @param p_record nuevo el record del juego a guardar
*/
void guardarRecord(int p_record) {
	FILE *archivo;
	//Se abre/crea el archivo para escribir
	archivo = fopen("record.txt", "w");
	//En caso de que se haya hecho bien se procede al guardado
	if (archivo != NULL) {
		//Guardamos la variable record
		fprintf(archivo, "%i \n", p_record);
		//Cerramos el archivo
		fclose(archivo);
		printf("\nGuardado realizado con exito.\n");
	}
	//Si se ha creado mal se muestra un mensaje
	else { printf("No se ha podido abrir/crear el archivo\n"); }
}
/**
* Carga la puntuacion record
* @return devuelve el record del juego
*/
int cargarRecord() {
	//Declaramos variables
	int record = 0;
	FILE *archivo;
	//Indicamos el archivo a leer
	archivo = fopen("record.txt", "r");
	//Leera los datos solo si se ha abierto bien el archivo
	if (archivo != NULL) {
		//Se lee la variable
		fscanf(archivo, "%i", &record);
		//Cerramos el archivo
		fclose(archivo);
	}
	else { printf("\nNo hay ningun record guardado por tanto el record actual es 0"); }
	//Se devuelve el record, sera 0 si no hay ninguno
	return record;
}
/**
* Comprueba las casillas vacias que hay y devuelve su numero
* @param p_tablero tablero que se comprobara
* @param p_num_columnas numero de columnas del tablero
* @param p_num_filas numero de filas del tablero
*/
int comprobarCasillasVacias(int * p_tablero, int p_num_columnas, int p_num_filas) {
	int casillas = 0;
	//Se recorre el tablero contando las casillas cuyo valor es 0
	for (int i = 0; i < p_num_filas; i++)
	{
		for (int j = 0; j < p_num_columnas; j++)
		{
			if (p_tablero[i*p_num_columnas + j] == 0)
			{
				//Si se encuentra una cuyo valor es 0 se añade a la cuenta
				casillas++;
			}
			
		}
	}
	//Devolvemos el total de baldosas vacias
	return casillas;
}
/**
* Obtiene las caracteristicas de la grafica e indica si puede correr la matriz
* @param p_num_columnas numero de columnas del tablero
* @param p_num_filas numero de filas del tablero
*/
void obtenerCaracteristicasCUDA(int p_num_columnas, int p_num_filas) {
	cudaDeviceProp prop;
	cudaGetDeviceProperties(&prop, 0);
	printf("Las caracteristicas de su grafica son las siguientes:\n");
	//Version y nombre de la grafica
	printf("Nombre: %s - Capability Version: %d.%d\n", prop.name, prop.major, prop.minor);
	printf("Limites de hilos por bloque: %d\n", prop.maxThreadsPerBlock);
	printf("Limites de hilos por SM: %d\n", prop.maxThreadsPerMultiProcessor);
	printf("Limites de memoria global: %zd\n B", prop.totalGlobalMem);
	printf("Limites de memoria compartida: %zd\n B", prop.sharedMemPerBlock);
	printf("Limites de registros: %d\n B", prop.regsPerBlock);
	printf("Numero de multiprocesadores: %d\n", prop.multiProcessorCount);
	//Caracteristicas de la matriz en memoria global sin teselar ni usar compartida
	printf("Las caracteristicas de la matriz a emplear:\n");
	printf("Cantidad de hilos a emplear: %d\n", p_num_columnas*p_num_filas);
	//Se empleara la matriz de enteros y un entero mas para la suma de puntuacion
	printf("Cantidad de memoria que se emplea: %zd\n", p_num_columnas*p_num_filas * sizeof(int) + sizeof(int));
	//Se comprueba que no se exceda el maximo de hilos por bloque para ver si puede con la matriz
	if (prop.maxThreadsPerBlock < p_num_columnas*p_num_filas) {
		printf("Error no hay suficientes hilos para ejecutar la matriz");
		exit(-1);
	}
	//Se comprueba que no se exceda el maximo de memoria global para ver si puede con la matriz
	if (prop.totalGlobalMem < p_num_columnas*p_num_filas * sizeof(int)) {
		printf("Error no hay suficiente memoria global para ejecutar la matriz");
		exit(-1);
	}
	//Comparacion en porcentajes
	printf("Porcentaje de aprovechamiento de hilos: %.2f %% \n", ((double)(p_num_columnas*p_num_filas) / prop.maxThreadsPerBlock) * 100);
}
/**
* Permite cambiar el color del texto y fondo de la consola
* @param p_fondo entero que permitira seleccionar un color para el fondo
* @param p_fuente entero que permitira seleccionar un color para el texto
*/
void Color(int p_fondo, int p_fuente) {

	HANDLE Consola = GetStdHandle(STD_OUTPUT_HANDLE);
	//Cálculo para convertir los colores al valor necesario
	int color_nuevo = p_fuente + (p_fondo * 16);
	//Aplicamos el color a la consola
	SetConsoleTextAttribute(Consola, color_nuevo);
}