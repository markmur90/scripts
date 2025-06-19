# Graylog Docker Stack

## Iniciar servicios

```bash
docker-compose up -d
```

## Detener servicios

```bash
docker-compose down
```

## Acceso web

URL: http://localhost:9000

Usuario: admin

Contraseña: admin

---

## ✅ Ventajas de esta Solución

- No depende de repositorios externos ni URLs caídas.
- Funciona en cualquier sistema con Docker instalado (Linux, Mac, Windows).
- Evita conflictos de paquetes o firmas GPG.
- Fácil de escalar o integrar con otros sistemas.

---

## 🧪 Verificación

Puedes ver los logs de Graylog con:

```bash
docker logs graylog-server
```
