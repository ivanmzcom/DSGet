# DSGet iOS

App iOS para gestionar Synology Download Station y File Station desde el iPhone y Apple Watch.

## Configuración

### Apple Watch - App Groups

Para que el Apple Watch acceda a las credenciales del iPhone, configurar los App Groups en Xcode:

1. Abrir `DSGet.xcodeproj` en Xcode
2. Target **DSGet** → **Signing & Capabilities**
3. Click en **+ Capability** → buscar **App Groups**
4. Crear el grupo: `group.es.ncrd.DSGet`
5. Target **iDSGet Watch App** → **Signing & Capabilities**
6. Click en **+ Capability** → **App Groups**
7. Crear/seleccionar el mismo grupo: `group.es.ncrd.DSGet`

## Requisitos

- iOS 18+
- watchOS 11+
- Xcode 15+

## Dependencias

- Swift Package Manager (sin dependencias externas)
