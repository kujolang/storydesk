# Contracts

Contract 1.0.0. StoryDesk owns: House Profile; Campaign; Idea; Editorial Brief; Assignment; Dependency; Status Event; Handoff Record; Daily Packet; Review Queue Entry. Records carry schema/tool versions, stable IDs, actor, timestamp, provenance, command, and payload. Consumers accept compatible 1.x, preserve safe unknown payload metadata, and reject incompatible majors. JSON uses `ok/data/error/tool_version/contract_version`. Offline upstream fixtures identify repository, tag, schema, and checksum.
