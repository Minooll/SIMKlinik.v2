# Draft RLS Matrix — Harus disesuaikan dengan schema nyata

| Resource | Anon | Pasien pemilik | Pasien lain | Dokter terkait | Petugas/Admin | Catatan |
|---|---|---|---|---|---|---|
| Public doctor directory | Read limited public fields if intended | Read | Read | Read | Manage if authorized | Hindari mempublikasikan data pribadi |
| Patient profile | Deny | Read/update permitted fields | Deny | Only if required for care and authorized | Only minimum operational fields | Separate auth identity from patient record |
| Appointment | Deny | Read own; create/cancel per rules | Deny | Read relevant assigned visits only | Manage within clinic scope | RLS plus trusted booking operation |
| Schedule | Deny or limited public read | Read available slots | Same | Read own schedule | Manage within scope | Do not expose internal notes |
| Queue ticket | Deny | Read own ticket | Deny | Read relevant queue | Operate queue within scope | Realtime authorization must also be tested |
| Queue events/audit | Deny | No raw audit access by default | Deny | Minimal relevant events | Authorized operational/audit role | Never expose sensitive internal details |
| Role assignment | Deny | Cannot self-assign | Deny | No | Trusted admin/service process | Client must not assign privileged role |

This is a policy design worksheet, not executable SQL and not proof that RLS is enabled.
