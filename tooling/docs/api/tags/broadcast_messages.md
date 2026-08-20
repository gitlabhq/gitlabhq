---
name: Broadcast messages
external_docs: https://docs.gitlab.com/api/broadcast_messages/
---
Use this API to interact with banners and notifications displayed in the UI. For more information, see [broadcast messages](../../../../doc/administration/broadcast_messages.md).

GET requests do not require authentication. All other broadcast message API endpoints are accessible only to administrators. Non-GET requests by:

- Unauthenticated users result in `401 Unauthorized`.
- Authenticated non-administrators result in `403 Forbidden`.
