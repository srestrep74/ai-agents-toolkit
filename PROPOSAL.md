# Preview of Structure

```csharp
copa-ai-platform
│
├── skills/
├── prompts/
├── architecture/
├── domain-context/
├── templates/
├── scripts/
└── .github
     copilot-instructions.md
```

### architecture/

It defines how the backend works technically . This is extremely important because Copilot use this instructions as **context of the repository** to generate consistent code .

An overview of this folder would be :

```csharp
architecture
   hexagonal.md
   cqrs.md
   scala-guidelines.md
   microservice-structure.md
   testing-strategy.md
```

An example of [hexagonal.md](http://hexagonal.md) :

```csharp
Layers:

domain
application
infrastructure

Rules:

domain cannot depend on infrastructure
ports live in domain
adapters live in infrastructure
```

### domain-context/

Here is where business domains are explained . For example :

```csharp
domain-context
   ibe.md
   payments.md
   wci.md
   myaccount.md
   mytrips.md
   copacom.md
```

An example of [ibe.md](http://ibe.md) :

```csharp
Domain: IBE (Intelligent Booking Engine)

Responsibilities:

flight search
pricing
reservation creation
shopping cart

Key concepts:

PNR
itinerary
fare
availability
```

### skills/

Here we define reproducible workflows or tasks . For our project, we must design skills by architecture , not by domain :

For example :

- CQRS Skills
  ```csharp
  skills/cqrs
     create-command
     create-command-handler
     create-query
     create-query-handler
  ```
- Domain Skills
  ```csharp
  skills/domain
     create-entity
     create-value-object
     create-domain-event
     create-domain-service
  ```
- Hexagonal Skills
  ```csharp
  skills/hexagonal
     create-port
     create-adapter
     create-rest-endpoint
     create-event-consumer
     create-event-producer
  ```
- Testing Skills
  ```csharp
  skills/testing
     create-unit-test
     create-integration-test
  ```
- DevOps Skills
  ```csharp
  skills/devops
     compare-env-vars
     create-dockerfile
  ```

### prompts/

Here we define high level commands for the agent .

```csharp
prompts
   plan-feature.prompt.md
   implement-feature.prompt.md
   review-pr.prompt.md
   debug-issue.prompt.md
```

For example , [plan-feature-prompt.md](http://plan-feature-prompt.md) :

```csharp
Analyze the feature request.

Output:

1 architecture design
2 commands
3 queries
4 domain entities
5 adapters
6 tests
```

So the dev writes :

> /plan-feature implement reservation cancellation

### copilot-instructions.md

This is the most important file in the repo. Copilot uses this file as the main global instructions of the project .

In this file, we are going to have our **Skill Catalog** that is one of the most effective and used patterns to scale skills. The idea is to have an index of skills , so Copilot searches the skill file only when it´s relevant.

The recommend structure is the following :

```csharp
1. Project Overview
2. Architecture Knowlegde
3. Domain Knowledge
4. Skill Catalog
5. Skill Loading Instructions
```

For example :

```csharp
# Copa Airlines Backend Development Instructions

These instructions guide GitHub Copilot when generating code for this repository.

This system is a distributed backend composed of multiple microservices organized by business domain.

---

# Project Overview

Tech Stack

- Scala 2
- JDK 11
- Microservices architecture
- Hexagonal Architecture
- CQRS pattern

Business domains include:

- IBE (Internet Booking Engine)
- Payments
- WCI (Web Check-in)
- Loyalty
- Notifications
- Documents

Each domain contains multiple microservices.

---

# Architecture Knowledge

The system architecture is documented in the following files:

| Topic | Path |
|------|------|
| Hexagonal Architecture | architecture/hexagonal.md |
| CQRS Pattern | architecture/cqrs.md |
| Microservice Structure | architecture/microservice-structure.md |
| Scala Coding Standards | architecture/scala-guidelines.md |

When generating backend code or modifying application structure,
load the relevant architecture document before generating code.

---

# Domain Knowledge

Business domain documentation is available in the following files.

| Domain | Path |
|------|------|
| IBE | domain-context/ibe.md |
| Payments | domain-context/payments.md |
| WCI | domain-context/wci.md |
| Loyalty | domain-context/loyalty.md |
| Notifications | domain-context/notifications.md |
| Documents | domain-context/documents.md |

When implementing a feature, first identify the domain
and load the corresponding domain context file.

---

# Skill Catalog

Use the following skill catalog to find specialized instructions.

| Skill | Description | Path |
|------|-------------|------|
| create-command | Create CQRS command and handler | `.github/skills/cqrs/create-command.md` |
| create-query | Create CQRS query and handler | `.github/skills/cqrs/create-query.md` |
| create-entity | Create domain entity | `.github/skills/domain/create-entity.md` |
| create-value-object | Create domain value object | `.github/skills/domain/create-value-object.md` |
| create-rest-endpoint | Create REST adapter | `.github/skills/hexagonal/create-rest-endpoint.md` |
| create-adapter | Create infrastructure adapter | `.github/skills/hexagonal/create-adapter.md` |
| create-unit-test | Generate Scala unit tests | `.github/skills/testing/create-unit-test.md` |
| debug-ci | Debug CI pipeline failures | `.github/skills/devops/debug-ci.md` |

---

# Skill Loading Rules

When a task matches a skill description:

1. Locate the skill in the catalog.
2. Load the referenced skill file.
3. Follow the procedure described in the skill.

Do not load unrelated skills.

Prefer using skills over generating code from scratch.

---

# Development Workflow

When implementing a new feature:

1. Identify domain and microservice.
2. Plan commands and queries.
3. Implement domain entities and services.
4. Add adapters.
5. Add tests.

Always follow architecture rules.
```

We may use as an improvement Skill Groups Catalog . The idea is to organize skills by categories, so the agent can find quickier the one to use without analizying all .

This is like an index mechanism.

- Without catalog → Copilot reviews all .
- With catalog → Copilot goes directly into the correct group .

When we have mutliples skills, for example :

```csharp
create-command
create-query
create-endpoint
create-port
create-adapter
generate-unit-test
generate-integration-test
fix-test
debug-ci
create-migration
create-env-vars
create-dockerfile
create-feature-toggle
```

If Copilot has to decide between all, the context gets heavy. So for this, a Skill Group Catalog is created.

A Skill Group is a logic category of skills. For example :

```csharp
# Skill Groups

Skills are organized in groups to simplify discovery.

| Group | Description |
|------|-------------|
| domain | Domain modeling skills |
| cqrs | Command and Query creation |
| api | REST endpoint generation |
| persistence | Repository and database tasks |
| testing | Unit and integration tests |
| devops | CI/CD and infrastructure |
| debugging | Troubleshooting errors |
```

This do not execute anything, but helps the agent **understand project´s taxonomy** .

Next to this group, we define de Skills catalog with its corresponding group :

```csharp
# Skills Catalog

| Skill | Group | Description |
|------|------|-------------|
| create-command | cqrs | Create a new CQRS command |
| create-query | cqrs | Create a query handler |
| create-endpoint | api | Generate REST endpoint |
| create-port | hexagonal | Create a domain port |
| create-adapter | hexagonal | Create infrastructure adapter |
| write-unit-test | testing | Generate unit tests |
| debug-ci | debugging | Analyze CI failures |
```

With this, Copilot now can think in the following way :

User prompt : “Create a command to cancel reservation” .

Copilot thinks :

- This is CQRS
- Search group=cqrs
- skill → create-command .

---

# Planner Agent

Now that we know how to integrate our skills with our Copilot Context (copilot-instructions) and business context (domain-context/) , it is time to design the flow of planning and implementation, when a new US comes .

### Final Structure

```csharp
copa-ai-platform
│
├── skills/
│
├── prompts/
│   ├── planner.md
│   └── implementer.md
│
├── architecture/
│
├── domain-context/
│
├── templates/
│
├── scripts/
│
├── work/
│   ├── user-stories/
│   ├── specs/
│   └── plans/
│
└── .github/
    copilot-instructions.md
```

Inside prompts/ folder we add two main files , where this are the main brains of the system. Then in work/ we have some temp directories were our planning and implement agents are going to gave us the implementation and design proposal for a given US .

### planner.md

This agent is charge of :

- User Story → Technical Spec → Implementation Plan

Basically it converts a business US into clear technical tasks .

The output is :

```csharp
spec.md
plan.md
```

Responsabilities :

- identify domain
- identify microservice
- identify entities
- define tasks
- respect architecture

### implementer.md

This agent takes the plan generated before and generates real code .

Input : plan.md

Responsabilities :

- execute one by one task
- use correct skills
- uses templates
- respect architecture
- generate tests

---

# Key aspects for success

- Design of templates : this must be rich of examples and quality code .
- Design of planner : this must be clear and full of rules and steps of how to design the planning .
- Full set of good design skills .

---

# Great example for base : Gentleman

- Take it from : https://www.youtube.com/watch?v=c5Gwx0RcxNE

# SDD - Spec Driven Development

On skills , we are going to use SDD with several sub-agents that are going to be in charge of an specific part of the process . The Skills are :

These are stored as individual Markdown files (e.g., SKILL.md) in your .vscode/skills/ directory. When the Orchestrator calls a skill, it swaps its "system personality" to follow that specific file's instructions:

1. sdd-init: The Project Setup Expert. Prepares the workspace, verifies the environment, and initializes the local memory/Engram database.

2. sdd-explore: The Context Researcher. Its sole purpose is to analyze the existing codebase, read documentation, and identify dependencies without making changes.

3. sdd-propose: The Product Analyst. Translates your high-level User Story into a formal proposal for the feature.

4. sdd-spec: The Requirement Architect. Turns the proposal into a strict set of functional and technical requirements (the "What").

5. sdd-design: The Technical Architect. Designs the classes, data structures, and APIs. This acts as a filter to ensure the code follows patterns (like DDD or Hexagonal) before a single line is written.

6. sdd-tasks: The Project Manager. Breaks down the design into atomic, sequential tasks (tickets). Its output is a clear, step-by-step checklist.

7. sdd-apply: The Implementer. This is the only agent that writes code. It reads the tasks, reads the source code, writes the implementation, and ensures it matches the specs.

8. sdd-verify: The QA Engineer. Runs tests, checks linting, and validates the output against the original acceptance criteria.

9. sdd-archive: The Documentation Specialist. Finalizes the cycle, updates the project docs, syncs with memory (Engram), and cleans up temporary files.

## The Orquestrator Agent

The previous skills were going to act as subagents, that are invoked via an principal agent that is the orchestrator.
This agent is going to live on .copilot-instructions.md for COPILOT CLI .
You don't talk to nine different programs. You interact with the Orchestrator (your IDE's AI chat, like Copilot or Cursor, running with the framework's instructions).

The Orchestrator's Role: It is a "Router of Decisions." It doesn't solve the problem; it manages the state machine.

Lazy Execution: When you run a command like /sdd-tasks, the Orchestrator:

Looks up the sdd-tasks/SKILL.md file.

Injects those specific instructions into the LLM's context.

Tells the LLM: "Adopt this persona, process the current state, and return the result."

Once the task is done, the LLM reverts to its baseline state, and the Orchestrator resumes control.

## Engram

Engram is a local-first knowledge base powered by a lightweight database (typically SQLite with FTS5 for full-text search). It operates via the Model Context Protocol (MCP), which allows your AI agents (like GitHub Copilot) to "read from" and "write to" this database as if it were a local file system, but with the intelligence of a semantic search engine.

How it works ?

Engram functions as a bridge between your code and the AI's "brain." Here is the cycle:

Saving (mem_save): When you finish a task, such as sdd-design or sdd-apply, the agent triggers a call to Engram. It doesn't just save the raw text; it extracts key "insights"—decisions made, library choices, architectural patterns, or bug fixes—and stores them in a structured, searchable format.

Indexing: Engram indexes these snippets, creating a "map" of your project's history and logic.

Querying (mem_search): When you start a new task tomorrow, the Orquestator doesn't start from zero. It performs a semantic search on Engram: "What did we decide about the document state synchronization last week?"

Context Injection: Engram returns only the most relevant, compressed "chunks" of that past knowledge, which the agent then injects into its current working memory.

The advantage in the agents :

A. Eliminating "Amnesia" (Context Preservation)
Without Engram, if you close your terminal, the agent forgets that you decided to use a specific pattern for the DocumentStatus service. When you return, the agent might suggest an entirely different approach, leading to inconsistent code. With Engram, the agent remembers the "why" behind every architectural decision.

B. Massive Token Efficiency (Cost Optimization)
This is the "killer feature" for costs:

The Problem: Sending your entire project history to the LLM for every single prompt is the fastest way to hit your token limits and inflate your API bill.

The Engram Fix: Instead of feeding the LLM 50,000 tokens of chat history, Engram feeds the LLM exactly 500 tokens of highly relevant, consolidated project history. You save money, and the agent becomes faster because it has less "noise" to process.

C. Preventing "Agent Schizophrenia"
By keeping a "Source of Truth" in the database, the agents stay aligned with your project's standards. If you define a coding standard in an early phase, Engram ensures that future sub-agents (like sdd-apply) adhere to those rules automatically, without you having to restate them every single time.

## Links

- SDD agents : https://github.com/Gentleman-Programming/agent-teams-lite
- Engram project : https://github.com/Gentleman-Programming/engram
