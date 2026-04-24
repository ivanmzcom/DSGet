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

## Subida a TestFlight

La subida está automatizada con Fastlane en `fastlane/Fastfile`. El bundle id de App Store Connect es `com.ivanmz.DSGet`.

### Requisitos

- Tener Xcode instalado y la sesión de Apple Developer configurada para el team `BH4ZLEBC89`.
- Tener las dependencias Ruby instaladas con `bundle install`.
- Tener una API key de App Store Connect disponible localmente. No commitear nunca el `.p8`.

### Autenticación

Fastlane acepta una de estas opciones:

```sh
APP_STORE_CONNECT_API_KEY_P8_PATH=/ruta/local/AuthKey_XXXXXXXXXX.p8 \
APP_STORE_CONNECT_ISSUER_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx \
bundle exec fastlane beta_all
```

O bien:

```sh
APP_STORE_CONNECT_API_KEY_PATH=/ruta/local/api_key.json \
bundle exec fastlane beta_all
```

### Lanes

Subir iOS y macOS a TestFlight:

```sh
bundle exec fastlane beta_all
```

Subir solo iOS:

```sh
bundle exec fastlane ios beta
```

Subir solo macOS:

```sh
bundle exec fastlane mac beta
```

Cada lane genera un `CFBundleVersion` con timestamp, archiva con firma automática y sube el binario a App Store Connect. Los artefactos locales se generan bajo `fastlane/build/` y están ignorados por Git.

### Verificación

Después de subir, comprobar el procesamiento con `asc`:

```sh
ASC_KEY_ID=XXXXXXXXXX \
ASC_ISSUER_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx \
ASC_PRIVATE_KEY_PATH=/ruta/local/AuthKey_XXXXXXXXXX.p8 \
asc builds list --app 6758262843 --limit 20 --output table
```

## Requisitos

- iOS 18+
- watchOS 11+
- Xcode 15+

## Dependencias

- Swift Package Manager (sin dependencias externas)
