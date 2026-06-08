# Calidad del Agua - Sistema de Monitoreo IoT para Acuicultura

**Calidad del Agua** es una aplicación móvil desarrollada en **Flutter** que permite monitorear en tiempo real los principales parámetros de calidad del agua en sistemas acuícolas. La aplicación se integra con la API-IOT para proporcionar información precisa y actualizada, facilitando la toma de decisiones y contribuyendo al bienestar de los organismos cultivados.

---

## Características Principales

### Monitoreo en Tiempo Real
Visualización instantánea de los datos obtenidos por los sensores instalados en el sistema IoT.

### Parámetros Monitoreados
Seguimiento continuo de variables críticas para la calidad del agua:

- Temperatura
- pH
- Oxígeno disuelto
- Sólidos disueltos totales (TDS)

### Otros Cálculos
Módulo especializado para mostrar indicadores complementarios derivados de los parámetros monitoreados.

### Exportación de Datos
Generación y descarga de reportes para el análisis y respaldo de la información recolectada.

### Gestión de Usuarios
Administración de usuarios mediante autenticación segura y control de acceso.

### Integración en la Nube
Sincronización de datos en tiempo real utilizando Firebase Firestore.

### Interfaz Moderna
Diseño intuitivo y adaptable para dispositivos móviles Android.

---

## Stack Tecnológico

### Frontend
- Flutter
- Dart

### Backend
- API-IOT

### Base de Datos y Servicios
- Firebase Firestore
- Firebase Authentication
- Firebase Cloud Messaging

### Comunicación
- HTTP Requests

### Herramientas
- GitHub
- Render

---

## Requisitos Previos

Antes de ejecutar el proyecto, asegúrate de tener instalado lo siguiente:

- Flutter SDK
- Dart SDK (incluido con Flutter)
- Android Studio o Visual Studio Code
- Un dispositivo Android físico o un emulador configurado
- Git

### Instalación de Flutter

Si aún no tienes Flutter instalado, puedes seguir la guía oficial:

**Documentación oficial de Flutter:**  
https://docs.flutter.dev/get-started/install

**Documentación proporcionada por el creador de la aplicación móvil**
https://drive.google.com/file/d/15leTLxrhI4YgJz92f566vcDXu7Y1QJyi/view?usp=sharing

### Verificar la instalación

Una vez instalado Flutter, ejecuta:

```bash
flutter doctor
```

Este comando verificará que todas las dependencias necesarias estén correctamente configuradas.

---

## Instalación y Uso Local

### Clonar el proyecto

```bash
git clone https://github.com/Proyectos-ITVH/Frontend-Flutter.git
```

### Acceder al directorio

```bash
cd Frontend-Flutter
```

### Instalar dependencias

```bash
flutter pub get
```

### Ejecutar la aplicación

```bash
flutter run
```

### Generar APK para pruebas

```bash
flutter build apk
```

---

## Seguridad

La aplicación implementa mecanismos de autenticación y autorización para garantizar el acceso seguro a la información.

- Autenticación mediante tokens.
- Envío de correos mediante Firebase Authentication.
- Comunicación segura con la API.
- Configuración centralizada de endpoints.
