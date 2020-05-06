# Proyecto 2 opcional: Bis

Bis es una aplicación realizada para la asignatura de **Programación Optimizada para Dispositivos Móviles** del máster de **Desarrollo de Software para Dispositivos Móviles** de la **Universidad de Alicante**.

Se nos propone complementar un juego/shooter de *macOS* desarrollando una aplicación de *iOS* que se conecte por Bluetooth (BLE) a la misma utilizando el framework **CoreBluetooh**. Para su correcto funcionamiento, se requiere:

 - Descubrir y hacer una escritura en una característica publicitada por un servicio del juego de *macOS*.
 - Publicitar 2 características (X e Y) en la aplicación de *iOS* y modificar su valor para permitir el movimiento de la mirilla dentro del juego de *macOS*.


Se ha hecho uso de los módulos siguientes de **CoreBluetooh**:

 - ****CBCentralManager**** para gestionar la conexión.
 - ****CBPeripheral**** para el descubrimiento de servicios y características externas.
 - ****CBPeripheralManager**** para publicar un servicio con características propias.

Para el movimiento de la mirilla, se ha hecho uso de la gravedad proporcionada por el framework **CoreMotion**.
