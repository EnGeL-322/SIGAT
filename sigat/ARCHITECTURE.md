# Arquitectura SIGAT

SIGAT queda preparado para crecer con una arquitectura modular y por capas.
El objetivo es evitar que compras, ventas, inventario, maestros, seguridad y
reportes terminen mezclados en paquetes globales dificiles de mantener.

## Estructura objetivo

```text
com.ramiro.sigat
  modules
    catalog
      web
      application
      domain
      infrastructure
    operations
      web
      application
      domain
      infrastructure
    inventory
      web
      application
      domain
      infrastructure
    security
      web
      application
      domain
      infrastructure
    reports
      web
      application
      domain
      infrastructure
  shared
    application
    domain
    infrastructure
```

## Modulos

- `catalog`: productos, proveedores y clientes.
- `operations`: compras, ventas y sus detalles.
- `inventory`: stock, IMEI y estado fisico de equipos.
- `security`: usuarios, roles, autenticacion y autorizacion.
- `reports`: reportes de ventas, bajo stock y futuras exportaciones.
- `shared`: codigo transversal que no pertenece a un solo modulo.

## Capas

- `web`: controladores REST, validacion de entrada y DTO de transporte.
- `application`: casos de uso, servicios transaccionales y orquestacion.
- `domain`: entidades, reglas de negocio puras y excepciones del dominio.
- `infrastructure`: repositorios, persistencia JPA, configuracion e integraciones externas.

## Regla de dependencias

La direccion correcta es:

```text
web -> application -> domain
application -> infrastructure
```

`domain` no debe depender de Spring, controladores, repositorios ni DTO de API.

## Migracion recomendada

La aplicacion actual funciona con paquetes globales:

```text
controllers
services
repositories
models
dto
config
```

Para no romper endpoints, la migracion debe hacerse de forma gradual:

1. Mover primero un modulo pequeno completo, por ejemplo `catalog`.
2. Mantener las rutas REST existentes para no romper el frontend.
3. Separar DTO de API y entidades JPA cuando el flujo ya este estable.
4. Repetir el proceso con `inventory`, `operations`, `reports` y `security`.
5. Ejecutar `mvn compile` despues de cada modulo.

## Base de datos

Esta mejora estructural no requiere cambios de base de datos.
La base configurada actualmente es `sigat_db`.
