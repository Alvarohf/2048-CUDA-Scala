/*====================================================================================
|                 Luis Alejandro Cabanillas Prudencio                                |
|                    Álvaro de las Heras Fernández                                   |
|                                                                                    |
|         16384 Juego que simula al 2048 implementado con Scala                      |
====================================================================================*/

object juego {

  //------------------------------FUNCIONES GENERICAS---------------------------------

  /**
    * Obtiene el valor de una posicion del tablero
    *
    * @param tablero tablero en el que buscara el valor
    * @param indice  posicion en el tablero de la que se obtendra el valor
    * @return Si existe el valor lo devuelve si no devuelve -1
    */
  def obtener(tablero: List[Int], indice: Int): Int = {
    //Si el tablero no esta vacio
    if (tablero.length > 0) {
      //Si el indice es la cabeza se devuelve
      if (indice == 1) tablero.head
      //Si no se quita otro elemento y se reduce el indice
      else obtener(tablero.tail, indice - 1)
      //Si esta fuera de rango devuelve -1
    } else -1
  }

  /**
    * Genera un valor aleatorio de un determinado conjunto
    *
    * @param dificultad Parametro que determinara los posibles valores a generar
    * @return Valor generado aleatoriamente para la dificultad dada
    */
  def crearValorRandom(dificultad: Int): Int = {
    //Conjunto de posibles valores a generar
    val valores = List(2, 4, 8)
    val random = util.Random;
    //Segun la dificultad coge unos u otros elementos del conjunto
    if (dificultad < 4) {
      val valor = obtener(valores, random.nextInt(dificultad) + 1)
      valor
    } else {
      val valor = obtener(valores, random.nextInt(3) + 1)
      valor
    }
  }

  /**
    * Genera una posicion hasta el tamano maximo
    *
    * @param tam tamano que no debe sobrepasar
    * @return posicion aleatoria dentro del rango
    */
  def crearRandomPos(tam: Int): Int = {
    val random = util.Random;
    //Valor aleatorio que se genera
    val pos = random.nextInt(tam) + 1
    pos
  }

  /**
    * Pone un valor dado en una lista en la posicion dada
    *
    * @param lista lista en la que se pondra el valor
    * @param valor valor que se introducira
    * @param pos   posicion en la que se introducira
    * @return lista con el valor introducido
    */
  def poner(lista: List[Int], valor: Int, pos: Int): List[Int] = {
    //Comprueba si esta vacia
    if (lista.length == 0) Nil
    //Si es la primera posicion se anade al principio
    else if (pos == 1) valor :: lista.tail
    //Si no se itera hasta llegar a ella
    else lista.head :: poner(lista.tail, valor, pos - 1)
  }

  //POSIBLE MEJORA
  /**
    * Pone un elemento en una posicion vacia con un valor aleatorio que depende de la dificultad
    *
    * @param lista      lista o tablero donde se pondran los valores
    * @param dificultad parametro que condiciona el valor a introducir
    * @return el tablero con el valor introducido
    */
  def poner(lista: List[Int], dificultad: Int): List[Int] = {
    //Se genera una posicion y un valor aleatorios
    val pos = crearRandomPos(lista.length)
    val valor = crearValorRandom(dificultad)
    //Comprueba si esta vacia
    if (lista.length == 0) Nil
    else {
      //Si la posicion esta vacia
      if (obtener(lista, pos) == 0)
      //Coloca el valor en ella
        poner(lista, valor, pos)
      else poner(lista, dificultad)
    }
  }


  /**
    * Genera un tablero relleno de ceros (vectorizado)
    *
    * @param tam tamano que tendra el tablero
    * @return tablero creado lleno de 0
    */
  def generarTab(tam: Int): List[Int] = {
    if (tam == 0) Nil
    //Llamada recursiva hasta que el tamano sea el deseado
    else 0 :: generarTab(tam - 1)
  }

  /**
    * Cuenta el numero de huecos que hay (posiciones a 0)
    *
    * @param tablero tablero en el que se contaran
    * @return numero de huecos del tablero
    */
  def huecosLibres(tablero: List[Int]): Int = {
    //Si el tablero no es vacio contamos
    if (tablero.length > 0) {
      //Cada vez que haya una celda vacia se suma uno y se llama recursivamente
      if (tablero.head == 0)
        huecosLibres(tablero.tail) + 1
      else
      //Si no es 0 se llama recursivamente sin contar
        huecosLibres(tablero.tail)
    } else 0
  }

  /**
    * Rellena el tablero con un numero de semillas segun una dificultad
    *
    * @param tablero     tablero que sera rellenado
    * @param numCasillas cantidad de casillas a rellenar
    * @param dificultad  dificultad que condicionara los valores de relleno
    * @return el tablero ya relleno
    */
  def rellenarTab(tablero: List[Int], numCasillas: Int, dificultad: Int): List[Int] = {
    if (tablero.length == 0) Nil
    //Mientras haya huecos y casillas se rellena el tablero
    else if ((huecosLibres(tablero) > 0) && (numCasillas != 0)) {
      rellenarTab(poner(tablero, dificultad), numCasillas - 1, dificultad)
    }
    //Finalmente devuelve el tablero
    else tablero
  }

  /**
    * Imprime el tablero con su formato adecuado
    *
    * @param lista    tablero que se va a mostrar por pantalla
    * @param columnas columnas que tendra cada fila
    */
  def imprimir(lista: List[Int], columnas: Int): Unit = {
    if (lista.length > 0) {
      //Cuando llega a la ultima columna pasa a la siguiente fila
      if (lista.length % columnas == 0) print("\n|")
      //Espacios que corrigen visualmente los valores del tablero
      val corregirEspacios = espacios(lista.head)
      //Imprime los valores del tablero con los espacios ajustados
      print(corregirEspacios + lista.head + "|")
      //Se vuelve a llamar a imprimir
      imprimir(lista.tail, columnas)
    }
  }

  /**
    * Espacios generados para cada valor
    *
    * @param numero valor del que dependen los espacios
    * @return espacios que ajustaran el valor
    */
  def espacios(numero: Int): String = {
    " " * (7 - digitos(numero))
  }

  /**
    * Calcula la cantidad de digitos del numero
    *
    * @param numero numero que se comprobara
    * @return digitos del numero
    */
  def digitos(numero: Int): Int = {
    //Si es menor que la condicion devuelve los digitos correspondientes hasta 7
    if (numero < 10) {
      1
    }
    else if (numero < 100) {
      2
    }
    else if (numero < 1000) {
      3
    }
    else if (numero < 10000) {
      4
    }
    else if (numero < 100000) {
      5
    }
    else if (numero < 1000000) {
      6
    }
    else {
      7
    }
  }

  /**
    * Elimina el valor de la posicion dada del tablero
    *
    * @param tablero tablero en el que se eliminara la posicion
    * @param indice  posicion que sera eliminada
    * @return tablero con la posicion eliminada
    */
  def eliminar(tablero: List[Int], indice: Int): List[Int] = {
    //Comprueba si no esta vacio
    if (tablero.length > 0) {
      //Comprueba si es la cabeza para anadir 0
      if (indice == 1) 0 :: tablero.tail
      //Si no vuelve a buscarlo recursivamente
      else tablero.head :: eliminar(tablero.tail, indice - 1)
    } else tablero
  }

  //--------------------------FUNCIONES AUXILIARES DE MOVIMIENTO--------------------------

  /**
    * Invierte una lista
    *
    * @param lista lista que se invertira
    * @return La lista invertida
    */
  def reverse(lista: List[Int]): List[Int] = {
    //Si es vacia devuelve la lista
    if (lista.length == 0) lista
    //Se anade el valor actual al final para construirla
    else reverse(lista.tail) ::: lista.head :: Nil
  }

  /**
    * Quita elementos del final del tablero
    *
    * @param tablero tablero del que se quitaran
    * @param limite  elementos del final que se quitaran
    * @return el tablero sin los elementos del final
    */
  def quitarHasta(tablero: List[Int], limite: Int): List[Int] = {
    //Cuando llega al limite para
    if (tablero.length == limite) Nil
    //Si no continua anadiendo
    else tablero.head :: quitarHasta(tablero.tail, limite)
  }

  //------------------------   MOVIMIENTOS SIMPLES  -------------------------------
  /**
    * Mueve abajo una fila completa si hay hueco (valor es 0)
    *
    * @param tablero  tablero que se movera
    * @param columnas Numero de columnas del tablero
    * @return devuelve el tablero con la fila bajada
    */
  def moverAbajo(tablero: List[Int], columnas: Int): List[Int] = {
    //Comprueba si esta vacio
    if (tablero.length > 0) {
      //Comprueba si el valor actual es distinto de cero
      if (tablero.head > 0) {
        //Si hay un hueco lo baja poniendolo en la posicion y borrando el actual
        if (obtener(tablero, columnas + 1) == 0) moverAbajo(poner(eliminar(tablero, 1), tablero.head, columnas + 1), columnas)
        //Si no continuamos recorriendo el tablero
        else tablero.head :: moverAbajo(tablero.tail, columnas)
        //Si no continuamos recorriendo el tablero
      } else tablero.head :: moverAbajo(tablero.tail, columnas)
      //Si es vacio se devuelve el tablero
    } else tablero
  }

  /**
    * Mueve arriba una fila completa si hay hueco (valor es 0) empleando mover abajo
    *
    * @param tablero  tablero que se movera
    * @param columnas Numero de columnas del tablero
    * @return devuelve el tablero con la fila subida
    */
  def moverArriba(tablero: List[Int], columnas: Int): List[Int] = {
    reverse(moverAbajo(reverse(tablero), columnas))
  }

  /**
    * Mueve a la derecha una columna completa todos los valores si hay hueco (valor es 0)
    *
    * @param tablero  tablero que se movera
    * @param columnas Numero de columnas del tablero
    * @return devuelve el tablero con la columna movida
    */
  def moverDerecha(tablero: List[Int], columnas: Int): List[Int] = {
    //Comprueba si esta vacio
    if (tablero.length > 0) {
      //Comprueba si el valor actual es distinto de cero
      if ((tablero.head > 0)) {
        //Si hay un hueco lo baja poniendolo en la posicion y borrando el actual
        if ((obtener(tablero, 2) == 0) && ((tablero.length) % columnas != 1)) moverDerecha(poner(eliminar(tablero, 1), tablero.head, 2), columnas)
        //Si no continuamos recorriendo el tablero
        else tablero.head :: moverDerecha(tablero.tail, columnas)
        //Si no continuamos recorriendo el tablero
      } else tablero.head :: moverDerecha(tablero.tail, columnas)
      //Si es vacio se devuelve el tablero
    } else tablero
  }

  /**
    * Mueve a la izquierda una columna completa todos los valores si hay hueco (valor es 0)
    *
    * @param tablero  tablero que se movera
    * @param columnas Numero de columnas del tablero
    * @return devuelve el tablero con la columna movida
    */
  def moverIzquierda(tablero: List[Int], columnas: Int): List[Int] = {
    reverse(moverDerecha(reverse(tablero), columnas))
  }

  //------------------------ MOVIMIENTO DE TODAS LAS CASILLAS-------------------------------
  /**
    * Mueve todo hacia abajo quitando los huecos
    *
    * @param tablero     tablero que movera
    * @param movimientos movimientos maximos para asegurar ningun hueco
    * @param columnas    columnas del tablero
    * @return el tablero con todos los valores en el fondo
    */
  def moverTodoAbajo(tablero: List[Int], movimientos: Int, columnas: Int): List[Int] = {
    //Lo mueve abajo hasta que movimientos sea 1
    if (movimientos == 1) tablero
    else moverTodoAbajo(moverAbajo(tablero, columnas), movimientos - 1, columnas)
  }

  /**
    * Mueve todo hacia arriba quitando los huecos
    *
    * @param tablero     tablero que movera
    * @param movimientos movimientos maximos para asegurar ningun hueco
    * @param columnas    columnas del tablero
    * @return el tablero con todos los valores en el borde superior
    */
  def moverTodoArriba(tablero: List[Int], movimientos: Int, columnas: Int): List[Int] = {
    //Lo mueve arriba hasta que movimientos sea 1
    if (movimientos == 1) tablero
    else moverTodoArriba(moverArriba(tablero, columnas), movimientos - 1, columnas)
  }

  /**
    * Mueve todo hacia la derecha quitando los huecos
    *
    * @param tablero     tablero que movera
    * @param movimientos movimientos maximos para asegurar ningun hueco
    * @param columnas    columnas del tablero
    * @return el tablero con todos los valores en el lateral derecho
    */
  def moverTodoDerecha(tablero: List[Int], movimientos: Int, columnas: Int): List[Int] = {
    //Lo mueve a la derecha hasta que movimientos sea 1
    if (movimientos == 1) tablero
    else moverTodoDerecha(moverDerecha(tablero, columnas), movimientos - 1, columnas)
  }

  /**
    * Mueve todo hacia la izquierda quitando los huecos
    *
    * @param tablero     tablero que movera
    * @param movimientos movimientos maximos para asegurar ningun hueco
    * @param columnas    columnas del tablero
    * @return el tablero con todos los valores en el lateral izquierdo
    */
  def moverTodoIzquierda(tablero: List[Int], movimientos: Int, columnas: Int): List[Int] = {
    //Lo mueve a la izquierda hasta que movimientos sea 1
    if (movimientos == 1) tablero
    else moverTodoIzquierda(moverIzquierda(tablero, columnas), movimientos - 1, columnas)
  }

  /**
    * Suma los valores horizontalmente una unica vez
    *
    * @param tablero    tablero que sumara
    * @param columnas   columnas del tablero
    * @param puntuacion puntuacion que se sumara
    * @param conteo     cantidad de combinaciones a sumar
    * @return el tablero sumado mas la puntuacion y conteo
    */
  def sumarHorizontal(tablero: List[Int], columnas: Int, puntuacion: Int, conteo: Int): List[Int] = {
    //Comprueba si no esta vacio
    if (tablero.length > 0) {
      //Comprueba si el actual es distinto de 0
      if ((tablero.head > 0)) {
        //Comprueba si el siguiente coincide en valor
        if ((obtener(tablero, 2) == tablero.head) && ((tablero.length) % columnas != 1))
        //Si lo hace lo suma poniendo a 0 el nuevo valor y dejando el actual con el doble ademas de calcular puntos y conteo
          sumarHorizontal(poner(eliminar(tablero, 2), tablero.head * 2, 1), columnas, puntuacion + tablero.head * 2, conteo + 1)
        //Si no se sigue recorriendo
        else tablero.head :: sumarHorizontal(tablero.tail, columnas, puntuacion, conteo)
        //Si no se sigue recorriendo
      } else tablero.head :: sumarHorizontal(tablero.tail, columnas, puntuacion, conteo)
      //Si es vacio se anade la puntuacion y conteo al final
    } else tablero ::: puntuacion :: conteo :: Nil
  }

  /**
    * Suma los valores verticalmente una unica vez
    *
    * @param tablero    tablero que sumara
    * @param columnas   columnas del tablero
    * @param puntuacion puntuacion que se sumara
    * @param conteo     cantidad de combinaciones a sumar
    * @return el tablero sumado mas la puntuacion y conteo
    */
  def sumarVertical(tablero: List[Int], columnas: Int, puntuacion: Int, conteo: Int): List[Int] = {
    //Comprueba si no esta vacio
    if (tablero.length > 0) {
      //Comprueba si el actual es distinto de 0
      if ((tablero.head > 0)) {
        //Comprueba si el siguiente coincide en valor
        if (obtener(tablero, columnas + 1) == tablero.head) {
          //Si lo hace lo suma poniendo a 0 el nuevo valor y dejando el actual con el doble ademas de calcular puntos y conteo
          sumarVertical(poner(eliminar(tablero, columnas + 1), tablero.head * 2, 1), columnas, puntuacion + tablero.head * 2, conteo + 1)
          //Si no se sigue recorriendo
        } else tablero.head :: sumarVertical(tablero.tail, columnas, puntuacion, conteo)
        //Si no se sigue recorriendo
      } else tablero.head :: sumarVertical(tablero.tail, columnas, puntuacion, conteo)
      //Si es vacio se anade la puntuacion y conteo al final
    } else tablero ::: puntuacion :: conteo :: Nil
  }

  //------------------------------ MOVIMIENTO AUTOMATICO SIN OPTIMIZAR--------------------------------
  /**
    * Genera un movimiento aleatorio
    *
    * @return el caracter que se ha generado
    */
  def movimientoAleatorio(): Char = {
    val random = util.Random;
    (random.nextInt(4) + 1) match {
      case 1 => 'a'
      case 2 => 'w'
      case 3 => 's'
      case 4 => 'd'
    }
  }

  //-------------------------------MOVIMIENTO OPTIMIZADO------------------------------------
  /**
    * Genera un movimiento en funcion a futuras puntuaciones y casillas vacias
    *
    * @param tablero     tablero que se calculara
    * @param columnas    numero de columnas del tablero
    * @param bloqueoEjeX Indica si se han bloqueado los movimientos horizontales
    * @param bloqueoEjeY Indica si se han bloqueado los movimientos verticales
    * @return el mejor movimiento para hacer
    */
  def movimientoOptimizado(tablero: List[Int], columnas: Int, bloqueoEjeX: Boolean, bloqueoEjeY: Boolean): Char = {
    //Si se bloquea un eje solo se puede mover en una direccion
    if (bloqueoEjeX) {
      movAleatorioEjeY()
    }
    //Si se bloquea un eje solo se puede mover en una direccion
    else if (bloqueoEjeY) {
      movAleatorioEjeX()
    }
    //Si no estan bloqueados se aplica la optimizacion
    else {
      //Se calculan las posibles puntuaciones en cada direccion y los huecos de cada direccion (aprovechamiento de simetria de los movimientos en una direccion)
      val puntuacionVertical = obtener(sumarVertical(moverTodoArriba(tablero, columnas, columnas), columnas, 0, 0), tablero.length + 1)
      val puntuacionHorizontal = obtener(sumarHorizontal(moverTodoIzquierda(tablero, columnas, columnas), columnas, 0, 0), tablero.length + 1)
      val huecosVertical = huecosLibres(sumarHorizontal(moverTodoIzquierda(tablero, columnas, columnas), columnas, 0, 0))
      val huecosHorizontal = huecosLibres(sumarVertical(moverTodoArriba(tablero, columnas, columnas), columnas, 0, 0))
      //Valores heuristicos definidos por los huecos disponibles y puntuaciones de las jugadas
      val heuristicaVertical = huecosVertical * 0.6 + puntuacionVertical * 0.4
      val heuristicaHorizontal = huecosHorizontal * 0.6 + puntuacionHorizontal * 0.4
      //Si la heuristica vertical es mayor que la horizontal el movimiento sera horizontal
      if (heuristicaVertical > heuristicaHorizontal) {
        movAleatorioEjeY()
      }
      else {
        movAleatorioEjeX()
      }
    }
  }

  /**
    * Genera un movimiento aleatorio en horizontal
    *
    * @return movimiento a realizar
    */
  def movAleatorioEjeX(): Char = {
    val random = util.Random;
    (random.nextInt(2) + 1) match {
      case 1 => 'a'
      case 2 => 'd'
    }
  }

  /**
    * Genera un movimiento aleatorio en vertical
    *
    * @return movimiento a realizar
    */
  def movAleatorioEjeY(): Char = {
    val random = util.Random;
    (random.nextInt(2) + 1) match {
      case 1 => 's'
      case 2 => 'w'
    }
  }

  /**
    * Funcion que selecciona el movimiento en funcion del modo
    *
    * @param modo modo del juego manual = t auto = f
    * @return devuelve el movimiento realizado
    */

  def movimiento(tablero: List[Int], columnas: Int, bloqueoEjeX: Boolean, bloqueoEjeY: Boolean, modo: Boolean): Char = {
    //Si el modo es manual lee el teclado
    if (modo) {
      scala.io.StdIn.readChar()
      //Si no genera un valor aleatorio
    } else {
      movimientoOptimizado(tablero, columnas, bloqueoEjeX, bloqueoEjeY)
    }
  }

  //----------------------------BUCLE DEL JUEGO------------------------------------
  /**
    * Bucle del juego que se encargara de llamar a las distintas funciones que permiten su funcionamiento
    *
    * @param tablero     tablero actual del juego
    * @param columnas    columnas del tablero
    * @param dificultad  dificultad elegida para el juego
    * @param casillas    casillas o semillas que se rellenaran cada vez
    * @param puntuacion  puntuacion actual de juego
    * @param conteo      conteo actual de combinanciones
    * @param bloqueoEjeX indica si se han bloqueado los movimientos horizontales
    * @param bloqueoEjeY indica si se han bloqueado los movimientos verticales
    * @param vidas       numero de vidas
    * @param modo        modo de juego elegido
    */
  def juego(tablero: List[Int], columnas: Int, dificultad: Int, casillas: Int, puntuacion: Int, conteo: Int, bloqueoEjeX: Boolean, bloqueoEjeY: Boolean, vidas: Int, modo: Boolean): Unit = {
    //Si bloquean los movimientos en ambas direcciones se acaba la partida
    if (bloqueoEjeX && bloqueoEjeY) {
      println("¡Has perdido la partida!")
      //Se llama al metodo nueva partida con una vida menos
      nuevaPartida(dificultad, vidas - 1, puntuacion, modo)
    }
    //Si todavia se puede mover se pide nuevo movimiento y se muestra el tablero y datos
    else {
      imprimir(tablero, columnas)
      println("\nPuntuacion: " + puntuacion + "\tConteo: " + conteo + "\tVidas: " + vidas)
      print("\nMovimiento: ")
      //Se genera el movimiento
      val tecla = movimiento(tablero, columnas, bloqueoEjeX, bloqueoEjeY, modo)
      //Segun el movimiento se llama a una direccion u otra
      println(tecla)
      tecla match {
        case ('w' | 'W') => {
          //Se suman hacia arriba los valores
          val tableroSumado = sumarVertical(moverTodoArriba(tablero, columnas, columnas), columnas, puntuacion, conteo)
          //Se comprueba la condicion de bloqueo del juego(si no hay mas huecos y la puntuacion no ha variado entre rondas)
          if ((huecosLibres(tablero) == 0) && (puntuacion == obtener(tableroSumado, tableroSumado.length - 1))) {
            println("Ya no puedes mover verticalmente")
            //Se vuelve a llamar con el eje ya bloqueado con los mismos parametros
            juego(tablero, columnas, dificultad, casillas, puntuacion, conteo, bloqueoEjeX, true, vidas, modo)
          } else {
            //Si no esta bloqueado llena el tablero y se actualiza el conteo y puntuacion
            juego(
              rellenarTab(moverTodoArriba(quitarHasta(tableroSumado, 2), columnas, columnas), casillas, dificultad),
              columnas, dificultad, casillas, obtener(tableroSumado, tableroSumado.length - 1), obtener(tableroSumado, tableroSumado.length), false, false, vidas, modo)
          }
        }
        case ('a' | 'A') => {
          //Se suman hacia la izquierda los valores
          val tableroSumado = sumarHorizontal(moverTodoIzquierda(tablero, columnas, columnas), columnas, puntuacion, conteo)
          //Se comprueba la condicion de bloqueo del juego(si no hay mas huecos y la puntuacion no ha variado entre rondas)
          if ((huecosLibres(tablero) == 0) && (puntuacion == obtener(tableroSumado, tableroSumado.length - 1))) {
            println("Ya no puedes mover horizontalmente")
            //Se vuelve a llamar con el eje ya bloqueado con los mismos parametros
            juego(tablero, columnas, dificultad, casillas, puntuacion, conteo, true, bloqueoEjeY, vidas, modo)
          } else {
            //Si no esta bloqueado llena el tablero y se actualiza el conteo y puntuacion
            juego(
              rellenarTab(moverTodoIzquierda(quitarHasta(tableroSumado, 2), columnas, columnas), casillas, dificultad),
              columnas, dificultad, casillas, obtener(tableroSumado, tableroSumado.length - 1), obtener(tableroSumado, tableroSumado.length), false, false, vidas, modo)
          }
        }
        case ('d' | 'D') => {
          //Se suman hacia la derecha los valores
          val tableroSumado = sumarHorizontal(reverse(moverTodoDerecha(tablero, columnas, columnas)), columnas, puntuacion, conteo)
          //Se comprueba la condicion de bloqueo del juego(si no hay mas huecos y la puntuacion no ha variado entre rondas)
          if ((huecosLibres(tablero) == 0) && (puntuacion == obtener(tableroSumado, tableroSumado.length - 1))) {
            println("Ya no puedes mover horizontalmente")
            //Se vuelve a llamar con el eje ya bloqueado con los mismos parametros
            juego(tablero, columnas, dificultad, casillas, puntuacion, conteo, true, bloqueoEjeY, vidas, modo)
          } else {
            //Si no esta bloqueado llena el tablero y se actualiza el conteo y puntuacion
            juego(
              rellenarTab(moverTodoDerecha(reverse(quitarHasta(tableroSumado, 2)), columnas, columnas), casillas, dificultad),
              columnas, dificultad, casillas, obtener(tableroSumado, tableroSumado.length - 1), obtener(tableroSumado, tableroSumado.length), false, false, vidas, modo)
          }
        }
        case ('s' | 'S') => {
          //Se suman hacia abajo los valores
          val tableroSumado = sumarVertical(reverse(moverTodoAbajo(tablero, columnas, columnas)), columnas, puntuacion, conteo)
          //Se comprueba la condicion de bloqueo del juego(si no hay mas huecos y la puntuacion no ha variado entre rondas)
          if ((huecosLibres(tablero) == 0) && (puntuacion == obtener(tableroSumado, tableroSumado.length - 1))) {
            println("Ya no puedes mover verticalmente")
            //Se vuelve a llamar con el eje ya bloqueado con los mismos parametros
            juego(tablero, columnas, dificultad, casillas, puntuacion, conteo, bloqueoEjeX, true, vidas, modo)
          } else {
            //Si no esta bloqueado llena el tablero y se actualiza el conteo y puntuacion
            juego(
              rellenarTab(moverTodoAbajo(reverse(quitarHasta(tableroSumado, 2)), columnas, columnas), casillas, dificultad),
              columnas, dificultad, casillas, obtener(tableroSumado, tableroSumado.length - 1), obtener(tableroSumado, tableroSumado.length), false, false, vidas, modo)
          }
        }
        case ('e' | 'E') => println("¡Hasta la próxima!")
        case default => {
          println("Direccion imposible!")
          juego(tablero, columnas, dificultad, casillas, puntuacion, conteo, bloqueoEjeX, bloqueoEjeY, vidas, modo)
        }
      }
    }
  }

  /**
    * Inicia una nueva partida si hay vidas suficientes
    *
    * @param dificultad nivel de dificultad de la partida
    * @param vidas      vidas disponibles para la partida
    * @param puntuacion puntuacion que tiene en la partida
    * @param modo       modo de juego
    */
  def nuevaPartida(dificultad: Int, vidas: Int, puntuacion: Int, modo: Boolean): Unit = {
    //Si todavia hay vidas sigue jugando
    if (vidas > 0) {
      //Todas las dimensiones y casillas que se rellenaran en funcion de la dificultad
      val dimensiones = List(4, 9, 14, 17)
      val casillasIniciales = List(2, 4, 6, 6)
      val casillas = List(1, 3, 5, 6)
      val dim = obtener(dimensiones, dificultad)
      //Relleno inicial del tablero
      val tableroRelleno = rellenarTab(generarTab(dim * dim), obtener(casillasIniciales, dificultad), dificultad)
      //Llamada al bucle del juego
      juego(tableroRelleno, dim, dificultad, obtener(casillas, dificultad), puntuacion, 0, false, false, vidas, modo)
    } else {
      println("Has perdido todas tus vidas :(\n")
      println("Puntuacion final: " + puntuacion)
    }
  }

  //------------------------------- MAIN ----------------------------------------------
  def main(args: Array[String]) {
    println("¡Bienvenido al juego 16384!\n")
    println("¿Que modo desea? (m:manual/a:automatico)\n")
    val modo = scala.io.StdIn.readChar()
    println("¿Qué dificultad desea?\n")
    val dificultad = scala.io.StdIn.readInt()
    nuevaPartida(dificultad, 3, 0, modo == 'm')
  }
}
