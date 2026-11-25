# Cómo está organizado NPI-MV y cómo trabajar en él

Guía para el equipo, revisada contra el código el 20 de noviembre de 2026.

El proyecto es una aplicación Flutter para Android con datos de ejemplo y almacenamiento local. La arquitectura simplificada ya está aplicada en el código. Su objetivo es que podamos encontrar lo que buscamos y modificar una funcionalidad sin atravesar varias clases que solo se pasan llamadas entre sí.

Esta es la explicación práctica para empezar. [ARCHITECTURE.md](ARCHITECTURE.md) recoge los contratos técnicos acordados y [REFACTOR_PLAN.md](REFACTOR_PLAN.md) conserva el alcance de la migración. Si cambia una responsabilidad, debemos actualizar estas guías junto al código.

## Índice

- [La idea general](#la-idea-general)
- [Qué significa cada pieza](#qué-significa-cada-pieza)
- [Mapa del repositorio](#mapa-del-repositorio)
- [Recorrido por las funcionalidades](#recorrido-por-las-funcionalidades)
- [Cómo se conectan las piezas](#cómo-se-conectan-las-piezas)
- [Datos, assets y dispositivos](#datos-assets-y-dispositivos)
- [Cómo hacer cambios](#cómo-hacer-cambios)
- [Errores, esperas y limpieza](#errores-esperas-y-limpieza)
- [Pruebas y límites actuales](#pruebas-y-límites-actuales)

## La idea general

Agrupamos el código por **lo que hace la aplicación**: acceso, inicio, eventos, orientación y servicios de la facultad. Dentro de cada funcionalidad dejamos juntos sus pantallas, estado, modelos y componentes.

Para entender una interacción normal basta con seguir este recorrido:

```text
La persona pulsa un botón
    → la pantalla llama a una acción del viewmodel
    → el viewmodel usa los datos o el dispositivo que necesita
    → actualiza su estado y avisa de que ha cambiado
    → la pantalla vuelve a dibujarse
```

Una pantalla sencilla puede resolverlo con su propio estado. La selección de idioma, por ejemplo, no tiene un viewmodel separado. Creamos una clase cuando tiene una responsabilidad útil, no para completar un esquema de carpetas.

La arquitectura sigue una versión sencilla de **MVVM**: la vista dibuja y el viewmodel mantiene el estado y las acciones de la funcionalidad. El término «modelo» se refiere a los datos que manejamos; no implica crear una carpeta `domain`.

## Qué significa cada pieza

| Pieza | Para qué sirve | Ejemplo actual |
|---|---|---|
| Pantalla | Dibuja la interfaz, recoge pulsaciones y abre pantallas o diálogos | `EventsScreen`, `DirectionsPage` |
| Widget auxiliar | Dibuja un componente y recibe datos o callbacks | `EventCard`, `FloorMap` |
| Viewmodel | Mantiene el estado de una pantalla o flujo y ofrece acciones | `EventsViewModel`, `DirectionsFlowViewModel` |
| Modelo | Da nombre y forma a los datos | `Event`, `ScheduleItem`, `Waypoint` |
| Clase de acceso | Lee o escribe datos, o consulta un dispositivo | `LocalStore`, `EventCatalog`, `LocationClient` |
| Entrada de movimiento | Captura sensores y reconoce gestos | `FloorMotionInput`, `EventTiltInput` |
| Datos constantes | Contenido de ejemplo o configuración editable | `sample_schedule.dart`, `data/routes.dart` |

### Pantallas y widgets

Aquí viven `BuildContext`, `Navigator`, `showDialog`, la composición visual y las animaciones. Un widget puede tener estado visual propio: una zona seleccionada, un formulario o una animación no necesitan convertirse automáticamente en un viewmodel.

Un componente pequeño usado solo por una pantalla puede ser privado en el mismo archivo. Si tiene bastante contenido o se usa en varios sitios, tiene sentido separarlo. La carpeta `widgets/` ayuda a agrupar estos componentes; no es una capa obligatoria.

### Viewmodels: qué son y qué pasa con los controllers

Un viewmodel es una clase que responde preguntas como «¿estamos cargando?», «¿qué eventos se muestran?» o «¿cuál es el siguiente paso de la ruta?», y ofrece acciones como `loadEvents()` o `nextFloor()`.

Normalmente extiende `ChangeNotifier`. Cuando cambia algo que la interfaz debe ver, llama a `notifyListeners()`. El widget escucha con `ListenableBuilder` o con un listener explícito.

Cuando antes llamábamos *controller* a una clase que mantenía el estado de una pantalla, estaba haciendo el trabajo de un viewmodel. Usamos el nombre `ViewModel` para dejarlo claro. Los controllers propios de Flutter, como `AnimationController` o `TransformationController`, siguen siendo herramientas visuales del widget.

Un viewmodel no abre pantallas ni muestra diálogos. Por ejemplo, el de direcciones indica que hay una llegada pendiente de confirmar; la pantalla escucha ese cambio y presenta el diálogo.

### Clases de acceso: repositories y services

Ahora tenemos clases concretas con un trabajo directo:

- `LocalStore` conoce las claves y el formato de las preferencias locales.
- `EventCatalog` lee el CSV y lo convierte en eventos.
- `LocationClient` consulta la ubicación y calcula proximidad.

Estos trabajos antes podían repartirse entre repository, implementación, service y datasource. Para este mock basta con estas clases. Los nombres describen lo que hacen y se usan directamente mediante sus constructores. No hay que añadir una interfaz o una clase intermedia para consumirlas.

Tampoco hay una carpeta global `domain`. Los modelos están en la funcionalidad que los necesita. Si una operación pura merece separarse, puede vivir allí como función o algoritmo: `event_ordering.dart` es un ejemplo. Los cálculos de calibración están en `input/` porque pertenecen al reconocimiento del movimiento.

## Mapa del repositorio

```text
NPI-MV/
├── README.md                  Entrada al proyecto y comandos básicos
├── NEXT.md                    Estado y siguiente acción de la sesión de trabajo
├── .fvmrc                     Selección del SDK mediante FVM
├── memoria_referencias/       Material de referencia, fuera del código de la app
└── npi/                       Paquete Flutter; ejecutar aquí sus comandos
    ├── lib/                   Código Dart de la aplicación
    │   ├── main.dart          Llama a runApp con NpiApp
    │   ├── app.dart           Arranque, objetos compartidos y pantalla inicial
    │   ├── auth/              Idioma, acceso y sesión
    │   ├── home/              Horario y eventos guardados
    │   ├── events/            Descubrir, descartar y recuperar eventos
    │   ├── orientation/       Planos, rutas y ubicación
    │   ├── miscellaneous/     Servicios e información de la facultad
    │   ├── qr/                Pantalla reutilizable de cámara QR
    │   ├── storage/           Persistencia local
    │   └── input/             Sensores y reconocimiento de movimiento
    ├── assets/                CSV e imágenes incluidos con la app
    ├── test/                  Pruebas de lógica y widgets
    ├── doc/                   Documentación compartida
    ├── pubspec.yaml           Dependencias y declaración de assets
    ├── pubspec.lock           Versiones resueltas de dependencias
    ├── analysis_options.yaml  Reglas del analizador
    ├── android/               Configuración e integración nativa Android
    ├── ios/, linux/, macos/, web/, windows/
    │                          Proyectos de plataforma presentes en Flutter
    └── build/                 Salida generada; no editar a mano
```

La presencia de una carpeta de plataforma no demuestra que esa versión esté adaptada o validada. El alcance actual es Android; la versión de quiosco con Leap sigue pendiente.

### Cómo se organiza una funcionalidad por dentro

Los archivos principales están en la raíz de su funcionalidad. Por ejemplo, en `events/` encontramos `event.dart`, `event_catalog.dart`, `events_screen.dart` y `events_view_model.dart`. Sus componentes visuales están en `events/widgets/`.

`orientation/data/` contiene constantes de planos y rutas. En este contexto, `data` significa «datos editables de orientación»: no recupera la antigua capa global de acceso a datos ni introduce datasources.

## Recorrido por las funcionalidades

### `auth/`: idioma, acceso y sesión

Empieza por [language_selection_screen.dart](../lib/auth/language_selection_screen.dart) y [sign_in_screen.dart](../lib/auth/sign_in_screen.dart).

La primera contiene la selección de idioma y sus elementos privados. Las opciones de idioma todavía no soportadas no constituyen un sistema de traducción implementado. La segunda ofrece las formas de acceso y utiliza `SignInViewModel`. El formulario de correo está en `login_page.dart` y `login_form.dart`; `LoginViewModel` realiza su acción de acceso.

[SessionState](../lib/auth/session_state.dart) mantiene la identidad actual en memoria. `username` es nulo para un invitado e `isSignedIn` indica si existe una identidad. Sus acciones son `restore()`, `signIn(username)`, `continueAsGuest()` y `signOut()`.

El acceso es simulado: cualquier texto QR no vacío sirve como identidad; en el formulario se guarda el correo. El campo de contraseña se valida en la interfaz, pero no se contrasta con una cuenta. No hay backend de autenticación ni registro real.

### `home/`: horario

[HomeScreen](../lib/home/home_screen.dart) presenta el horario y abre las otras funcionalidades. [HomeViewModel](../lib/home/home_view_model.dart) mantiene el día seleccionado y carga los eventos guardados de la sesión actual.

`ScheduleItem` es el dato que dibuja una tarjeta de horario. `sample_schedule.dart` contiene las clases y eventos de ejemplo. El horario combina esos datos con hasta cuatro eventos guardados para usuarios identificados; la distribución por días sigue siendo de demostración. No debe interpretarse como una agenda académica sincronizada.

Cuando se vuelve del catálogo, Home recarga sus eventos guardados. Al cerrar sesión cambia la identidad compartida; los eventos guardados de ese usuario permanecen en el dispositivo.

### `events/`: catálogo, tarjetas y recuperación

Aquí hay dos viewmodels con responsabilidades distintas:

| Clase | Trabajo |
|---|---|
| `EventsViewModel` | Cargar, filtrar y ordenar eventos; guardar, descartar y reiniciar las colecciones |
| `SwipeDeckViewModel` | Arrastre táctil, desplazamiento y rotación de la tarjeta, tiempos de animación y coordinación del tutorial |

La separación permite que el gesto termine llamando a una acción de eventos sin que la lógica de persistencia necesite saber cuántos píxeles se ha movido la tarjeta.

[EventsScreen](../lib/events/events_screen.dart) crea un `EventsViewModel` y lo pasa a su lista. [DiscardedEventsScreen](../lib/events/discarded_events_screen.dart) crea otra instancia de la misma clase con `discardedOnly: true`. Cada pantalla tiene su lista y su carga; ambas usan el mismo catálogo, almacenamiento y sesión. No son dos autoridades globales sobre la misma pantalla.

`EventCard` dibuja los datos y recibe flags y callbacks. `event_ordering.dart` contiene la ordenación por preferencias y fecha. `pan_gesture.dart` y `swipe_state.dart` describen el arrastre y sus estados visuales; `tilt_tutorial_manager.dart` mantiene los pasos del tutorial.

El catálogo muestra eventos futuros. Guardar y descartar son operaciones excluyentes para un mismo ID. Un invitado puede apartar una tarjeta mediante guardar durante esa visita, pero no crea un evento guardado persistente; sus descartes sí usan el espacio local de invitado. El reinicio de colecciones se aplica a usuarios identificados.

### `orientation/`: explorar el plano y seguir una ruta

Hay dos trabajos principales:

- [FacultyMapScreen](../lib/orientation/faculty_map_screen.dart) permite explorar o seleccionar una zona del plano. `FacultyMapViewModel` mantiene la planta y sus límites, además del feedback de la interacción.
- [DirectionsPage](../lib/orientation/directions_page.dart) presenta el flujo de indicaciones. `DirectionsFlowViewModel` mantiene destino, origen, ruta, paso actual e historial, y decide cuándo consultar proximidad.

`OriginMapPage` permite elegir el origen mediante el plano. Los modelos son `MapZone` y `Waypoint`. Los widgets dibujan el mapa, las zonas, la guía, el tutorial y los avisos de ubicación.

Para editar contenido:

- `data/floors.dart` reúne nombres, imágenes y zonas de cada planta.
- Los archivos `*_zones.dart` contienen la geometría y los datos de sus zonas.
- `data/routes.dart` contiene los puntos de las rutas interiores y exteriores.

Las plantas se indexan desde cero: sótano `0`, baja `1`, primera `2`, segunda `3`, hasta quinta `6`.

[LocationClient](../lib/orientation/location_client.dart) encapsula permisos, consulta GPS y proximidad. Si la ubicación falta o no permite decidir con suficiente precisión, el flujo ofrece una alternativa manual. La ruta combinada une la parte interior y exterior evitando repetir la entrada común. El QR de origen sigue siendo un mock: cualquier resultado aceptado representa el aula 2.7.

### `qr/`: una cámara que devuelve texto

[QrScannerScreen](../lib/qr/qr_scanner_screen.dart) usa `mobile_scanner` y administra su cámara. Devuelve `String?`: texto para un escaneo válido o `null` si se cancela. Devuelve el primer texto no vacío; quien la abre decide qué significado darle.

Por eso sirve tanto para acceso como para origen de una ruta. La cámara no conoce usuarios, sesiones ni aulas. No necesita su propio repository, modelo de resultado o viewmodel para envolver ese retorno.

### `miscellaneous/`: servicios de la facultad

`MiscellaneousPage` presenta el catálogo constante de `service_options.dart`, cuyos elementos usan `ServiceOption`. Los componentes visuales están en `widgets/`. Para cambiar una descripción o un enlace, empezamos por el catálogo. Esta sección no necesita un viewmodel de carga ni un repository mientras sus datos sean constantes.

## Cómo se conectan las piezas

### Compartir una dependencia no significa hacerla global

[NpiApp](../lib/app.dart) obtiene las preferencias, crea `LocalStore` y `SessionState`, y mantiene un `EventCatalog`. Restaura la sesión antes de mostrar la pantalla inicial. Si falla el arranque, muestra un error con reintento.

```text
NpiApp
├── LocalStore                 Preferencias persistidas
├── SessionState → LocalStore  Identidad actual y acciones de sesión
└── EventCatalog               Catálogo CSV compartido y cacheado
          ↓ se pasan por constructores
     Pantallas → sus viewmodels y componentes
```

Pasar una dependencia por constructor significa entregarla expresamente al crear un objeto. Este fragmento reproduce el patrón de la pantalla de eventos:

```dart
_viewModel = EventsViewModel(
  session: widget.session,
  store: widget.store,
  catalog: widget.catalog,
);
_viewModel.loadEvents();
```

La pantalla recibe esos objetos de quien la abre. No crea otros para sustituirlos. Así podemos saber qué necesita cada clase leyendo su constructor, y Home y eventos ven la misma sesión.

`LocalStore` conserva datos entre ejecuciones. `SessionState` es el estado vivo durante la ejecución. `EventCatalog` conserva en memoria el CSV ya leído y comparte una carga en curso si dos consumidores lo solicitan a la vez. Cada uno resuelve un problema distinto.

### Quién crea y quién destruye

| Objeto | Quién lo crea | Quién termina su uso |
|---|---|---|
| `SessionState` compartido | `NpiApp` | `NpiApp` llama a `dispose()` |
| `LocalStore`, `EventCatalog` | `NpiApp` | Actualmente no requieren `dispose()` |
| Viewmodel de una pantalla | El estado de esa pantalla, normalmente en `initState()` | La misma pantalla, en `dispose()` |
| Viewmodel prestado a un hijo | Su pantalla o componente propietario | El hijo no lo destruye |
| Captura de movimiento | El componente que la utiliza | Ese componente la detiene y libera |
| Cámara QR | `QrScannerScreen` | La propia pantalla del escáner |

Por ejemplo, la lista de tarjetas recibe prestado `EventsViewModel`, pero crea su propio `SwipeDeckViewModel` y `EventTiltInput`. Libera estos dos y deja el primero a la pantalla que lo creó.

### Ejemplo: descartar un evento y volver a Home

1. La persona arrastra la tarjeta a la izquierda.
2. `SwipeDeckViewModel` interpreta el arrastre y coordina la animación.
3. Llama a `EventsViewModel.discardEvent(event)`.
4. El viewmodel pide a `LocalStore` que persista el descarte para el usuario actual.
5. Al terminar, recarga la lista visible y notifica el cambio.
6. La lista se redibuja. Si se abre recuperación, esa pantalla carga los descartados con su propia instancia.
7. Al volver de recuperación se recarga descubrimiento; al volver del catálogo se recarga Home.

Estos retornos explícitos cubren la actualización entre pantallas. No hay un bus global de eventos ni se fuerza la sincronización recreando toda la pantalla con una clave nueva.

## Datos, assets y dispositivos

### Lo que guardamos y dónde

[LocalStore](../lib/storage/local_store.dart) es el lugar para leer y escribir preferencias. Recibe `SharedPreferences` ya inicializado. Las lecturas son síncronas; las escrituras devuelven `Future<void>` y se esperan con `await`.

| Dato | Dónde se encuentra |
|---|---|
| Identidad durante la ejecución | `SessionState.username` |
| Identidad persistida y modo invitado | `LocalStore`, claves `user_session` y `guest_session` |
| IDs guardados y descartados por usuario | `LocalStore`, claves `user_events` y `discarded_events` |
| Preferencias de categorías antiguas | Lectura compatible de `usuarios` en `LocalStore` |
| Primera entrada y tutoriales completados | Getters y métodos específicos de `LocalStore` |
| Detalles de los eventos | CSV, a través de `EventCatalog` |
| Clases de ejemplo, rutas y servicios | Constantes Dart en su funcionalidad |

Solo `SessionState` debe solicitar las escrituras de identidad. Los demás consumidores consultan la sesión compartida. Para eventos se guardan IDs, no una segunda copia completa del catálogo.

`LocalStore` ordena las escrituras para evitar que dos modificaciones simultáneas de una colección se pisen. Guardar elimina ese ID de descartados y descartar lo elimina de guardados. Las claves y formatos previos se conservan; no los cambiamos sin una migración. Este almacenamiento no ofrece transacciones de base de datos: si falla una parte de una escritura compuesta, no hay garantía de deshacer lo anterior.

### Assets: archivos incluidos con la aplicación

`npi/assets/` contiene archivos que se empaquetan con la app, como imágenes o CSV. `pubspec.yaml` declara las carpetas que Flutter debe incluir. Un asset no es una clase de acceso ni una capa de arquitectura: es un recurso.

El catálogo activo lee `assets/expanded_events.csv` mediante `EventCatalog`. También existe `assets/events.csv`, pero no es el archivo que carga ese catálogo. Los planos están en `assets/orientation/`, las fotos de pasos en `assets/orientation/waypoints/` y las imágenes del tutorial en `assets/floor_movement_gesture_tutorial/`.

El código puede usar `AssetImage` o `Image.asset` directamente para presentar imágenes. Para los eventos necesitamos parsing, caché y manejo de errores, por eso hay una clase de acceso. Editar las preferencias del teléfono no modifica un asset empaquetado.

### Movimiento: reconocer un gesto y ejecutar una acción

En `input/` tenemos dos entradas concretas porque los algoritmos actuales son diferentes:

- `FloorMotionInput`: sensores, calibración y reconocimiento de subir o bajar; usa los helpers `calibrate_floor_motion.dart`, `process_floor_motion.dart` y sus modelos.
- `EventTiltInput`: sensores e integración del movimiento para las tarjetas; `tilt_gesture.dart` reconoce la secuencia de inclinación y retorno.

La pantalla del mapa las conecta así:

```dart
_motionInput = FloorMotionInput(
  onUp: _viewModel.nextFloor,
  onDown: _viewModel.previousFloor,
);
_motionInput.start();
```

El input reconoce «subir»; `FacultyMapViewModel` decide si queda una planta superior. En eventos, el input comunica guardar, descartar o progreso al viewmodel de interacción; este llama a las acciones de eventos.

Crear el input no inicia la captura. `start()` la activa, `stop()` la detiene y `dispose()` libera sus recursos. El propietario coordina estas llamadas con la actividad de la pantalla y de la app. Los controles manuales siguen disponibles si no hay sensores compatibles.

Para la futura versión PC, la intención es que una integración Leap termine invocando las mismas acciones. Aún faltan probar el dispositivo, el SDK y la conexión local, y decidir los gestos del quiosco. No existe todavía `leap_client.dart`, una conexión WebSocket implementada ni un paquete compartido entre aplicaciones en esta arquitectura.

## Cómo hacer cambios

### Encontrar el archivo antes de añadir otro

| Quiero cambiar… | Empiezo por… |
|---|---|
| Aspecto de una tarjeta de evento | `events/widgets/event_card.dart` |
| Qué eventos aparecen y en qué orden | `events/events_view_model.dart` y `event_ordering.dart` |
| Columnas o interpretación del CSV | `events/event.dart` y `event_catalog.dart` |
| Guardado de favoritos | `storage/local_store.dart` y la acción que lo solicita |
| Duración o desplazamiento de un swipe | `events/swipe_deck_view_model.dart` y sus widgets |
| Umbrales para reconocer una inclinación | `input/` |
| Una planta o el contorno de una zona | `orientation/data/` |
| Los pasos y fotos de una ruta | `orientation/data/routes.dart` y assets de waypoints |
| Una decisión del flujo de indicaciones | `orientation/directions_flow_view_model.dart` |
| El diálogo que muestra esa decisión | `orientation/directions_page.dart` |
| El horario de ejemplo | `home/sample_schedule.dart` |
| Un servicio de la facultad | `miscellaneous/service_options.dart` |
| Qué se abre al arrancar | `app.dart` |

### Añadir una acción a una funcionalidad existente

Por ejemplo, para añadir una operación sobre la lista de eventos:

1. Definir qué hace y qué debe ocurrir si falla o se pulsa dos veces.
2. Añadir la acción a `EventsViewModel` si modifica el estado de esa lista.
3. Si necesita persistencia nueva, añadir una operación explícita a `LocalStore` y resolver su compatibilidad con datos existentes.
4. Conectar el botón o gesto desde el widget y esperar el resultado.
5. Reflejar carga, error y resultado en la interfaz; probar las decisiones relevantes.

Si solo cambia el color de un botón, basta con editar su widget. Si solo cambia un texto del catálogo de servicios, basta con editar sus datos.

### Añadir una pantalla

La colocamos en la funcionalidad a la que pertenece y le pasamos sus dependencias por constructor. Creamos un viewmodel cuando tiene carga, decisiones o un flujo que mantener. La pantalla crea esa instancia, escucha sus cambios y la libera al salir.

Si abre otra pantalla, la navegación se queda en el widget. Puede esperar el retorno y recargar después, como hace Home al volver de eventos. Los hijos reciben datos y callbacks, o una instancia prestada cuando realmente comparten el mismo estado de flujo.

### Añadir datos o un dispositivo diferente

Primero comprobamos si basta con ampliar una clase existente. Un nuevo origen de datos con trabajo propio puede justificar una clase concreta junto a su funcionalidad. Si después aparece una necesidad real de varias implementaciones intercambiables, evaluamos una interfaz entonces.

Para probar el código actual ya hay puntos pequeños de sustitución: `EventCatalog(readCsv: ...)` permite suministrar CSV en memoria y `LocationClient(locate: ...)` permite suministrar una lectura de ubicación. No hace falta crear una jerarquía completa de repositories para esas pruebas.

## Errores, esperas y limpieza

`Future<T>` significa que el resultado estará disponible después. `await` espera ese resultado y permite capturar un fallo con `try/catch`. Devolver `Future<void>` sigue siendo útil: permite esperar a que la operación haya terminado aunque no devuelva un dato.

Aplicamos estas reglas:

- Mostrar carga y error cuando una operación puede tardar o fallar. Los nombres habituales son `isLoading`, `isMutating` y `error`.
- Esperar la persistencia antes de comunicar éxito y bloquear confirmaciones repetidas mientras se está escribiendo.
- Dejar el estado ocupado desactivado en un `finally`, también si hay error.
- Tratar la cancelación como un resultado normal cuando procede, como el `null` del escáner.
- Si una respuesta llega después de salir o cambiar de sesión, ignorarla. Los contadores de solicitud de los viewmodels evitan aplicar respuestas antiguas.
- Quitar listeners y cancelar timers y suscripciones al liberar su propietario. Un widget hijo no debe destruir una instancia que recibió prestada.
- Mostrar diálogos y navegar desde callbacks o listeners. `build()` puede ejecutarse muchas veces; no debe lanzar esos efectos por el hecho de dibujar.

En una carga, el viewmodel suele guardar el mensaje en `error`. En una acción que escribe, puede además propagar la excepción para que su consumidor no continúe como si hubiera terminado bien. Algunas acciones de Home devuelven un `bool` para indicar éxito. Hay que revisar el contrato concreto y manejar el resultado, sin añadir un tipo genérico de resultado para todas las operaciones.

## Pruebas y límites actuales

Las pruebas están en `npi/test/`:

| Archivo | Qué comprueba |
|---|---|
| `storage_session_test.dart` | Datos previos, escrituras concurrentes y fallos/cambios de sesión |
| `feature_state_test.dart` | Caché/reintento del catálogo, operaciones de eventos y estado de Home |
| `qr_access_test.dart` | Identidad simulada por QR y cancelación |
| `app_flow_test.dart` | Arranque, restauración, acceso y cierre de sesión |
| `events_screen_test.dart` | Swipe manual, recuperación y reinicio sin sensores |
| `orientation_flow_test.dart` | Flujo de rutas, respuestas GPS antiguas y alternativa manual |
| `input_test.dart` | Reconocimiento de gestos, captura y límites del mapa |

Para cambios de código, ejecutar desde `npi/`:

```bash
fvm flutter analyze
fvm flutter test
```

La validación del refactor del 20 de noviembre terminó con 24 pruebas pasando y sin incidencias del analizador. Es una referencia de esa revisión, no una garantía sobre cambios futuros. Esta guía se ha comprobado mediante lectura de código, enlaces y diff; escribirla no requiere repetir las pruebas de Flutter.

Todavía hay que validar en Android la cámara y sus permisos, el GPS, los tutoriales, la calibración y los gestos, y el comportamiento al pasar a segundo plano y volver. Las pruebas con datos simulados no establecen compatibilidad con hardware. Para esa revisión local:

```bash
cd npi
fvm flutter run -d <android-device-id>
```

La arquitectura organiza el mock actual. El backend real, la adaptación al quiosco, la conexión Leap y las decisiones de compartir código entre repositorios siguen siendo trabajos separados.
