# Architecture

Overview of the project architecture, key design decisions, and system boundaries.

## High-Level Overview

<!-- Describe your system architecture: monolith, microservices, monorepo, or hybrid. -->
<!-- Include a Mermaid diagram if helpful. -->

TODO: Add architecture diagram or description.

## Layers

<!-- Document your project's layer structure. Examples:
  - Domain (entities, value objects, exceptions)
  - Application (use cases, services, ports)
  - Infrastructure (adapters, repositories, controllers, config)
-->

TODO: Map your layers and their boundaries.

## Key Decisions

See the `adr/` directory for Architecture Decision Records.

## See Also

- [Operations](../operations.md) — runtime ops, supervisor commands, data dirs
- [Session Schema](../session-schema.md) — layout of `$IDNA_DATA/<session>/`
- [Patterns](patterns.md) — naming conventions, error hierarchy, data flow
- [Ubiquitous Language](ubiquitous-language.md) — shared domain vocabulary
- [Configuration](../standards/configuration.md) — environment variables, config files, priority chain
- [Deployment](../guides/deployment.md) — deployment steps and platform setup
- [Troubleshooting](../guides/troubleshooting.md) — common issues and solutions
- Visual explainers + brand galleries live in `~/.roxabi/forge/idna/` (forge skill)
