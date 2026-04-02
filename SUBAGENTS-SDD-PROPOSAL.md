# SubAgents in Copilot

# PARTE 1 — Cómo Funcionan los Subagentes en GitHub Copilot CLI

## El Modelo Mental Correcto: No es "Task tool", es el Ecosistema Completo

Lo primero que hay que entender para no confundirse es que GitHub Copilot CLI **sí tiene** un mecanismo equivalente al `Task tool` de Claude Code, y se llama simplemente `task` (como herramienta interna), pero lo que realmente define el sistema de subagentes en Copilot CLI es una tríada de conceptos que trabajan juntos: los **custom agents** definidos como archivos `.agent.md`, la **delegación automática** que hace el modelo principal cuando detecta que una tarea encaja con un agente especializado, y los **modos de ejecución** (interactive, autopilot, plan, fleet) que determinan cómo se orquesta todo el trabajo. Cuando la documentación habla de "subagentes", se refiere a cualquier instancia de agente temporal que se crea para manejar una subtarea específica, y estos subagentes pueden ser tanto los agentes nativos built-in (Explore, Task, Code Review, Plan) como tus propios custom agents definidos en archivos `.agent.md`.

## La Ventana de Contexto de los Subagentes: Sí, es Independiente

Cuando Copilot lleva a cabo una tarea usando un custom agent, el trabajo se realiza a través de un subagente, que es un agente temporal que se levanta para completar la tarea. El subagente tiene su propia ventana de contexto, que puede poblarse con información que no es relevante para el agente principal. De esta manera, especialmente para tareas grandes, partes del trabajo pueden delegarse a custom agents sin contaminar la ventana de contexto del agente principal. El agente principal puede entonces enfocarse en planificación y coordinación de alto nivel. Esto es exactamente el mismo principio que ATL describe: el orquestador mantiene contexto mínimo y los subagentes operan con contexto fresco e independiente. La diferencia con Claude Code es que en Copilot CLI la delegación puede ser tanto **explícita** (tú le dices qué agente usar) como **implícita** (el modelo decide solo si el trabajo encaja con algún agente disponible).

Esta independencia de contexto es técnicamente real y no cosmética. Cada subagente tiene su propio loop de ejecución, su propio historial de mensajes, y su propia ventana de tokens que no comparte con el agente padre. Los subagentes reciben IDs legibles por humanos basados en su nombre (por ejemplo, `math-helper-0`), y hay un hook `subagentStart` que se dispara cuando se levanta un subagente, permitiendo inyección de contexto adicional. Esto es importante para tu framework porque significa que puedes usar ese hook para inyectar automáticamente el contexto de Engram al inicio de cada subagente, sin necesidad de que el orquestador lo haga manualmente en el prompt.

## Los Cuatro Modos de Ejecución y Su Relevancia para SDD

GitHub Copilot CLI soporta cuatro modos de agente primarios: Interactive (request-response, aprobación por herramienta), Autopilot (ejecución autónoma sin aprobación por paso), Plan (crea un plan multi-paso para revisión antes de ejecutar), y Fleet (orquesta múltiples subagentes trabajando en paralelo para subtareas independientes).

Para tu framework SDD, esto tiene implicaciones muy concretas. El modo **Interactive** es el default y es donde el orquestador vive: el desarrollador habla con él, el orquestador lanza subagentes y presenta resultados, pero el humano sigue en control de cada aprobación. El modo **Autopilot** es ideal para la fase `sdd-apply` donde ya tienes un plan de tareas claro y quieres que el agente implemente sin interrupciones. El modo **Plan** es perfecto para usar antes de invocar `/sdd-ff`: le pides a Copilot que construya el plan de todas las fases que va a ejecutar, lo revisas, y luego lo apruebas. El modo **Fleet** es el equivalente al paralelismo que ATL describe para `sdd-spec` y `sdd-design`: Fleet orquesta múltiples subagentes trabajando en paralelo para ejecutar subtareas descompuestas de manera eficiente. El orquestador de Fleet descompone la tarea en subtareas paralelizables, los subagentes ejecutan concurrentemente, y los resultados se sintetizan en una respuesta cohesiva.

## Los Custom Agents: El Equivalente Exacto de las Skills de ATL

Cada custom agent se define mediante un archivo Markdown con extensión `.agent.md`. La estructura de estos archivos tiene YAML frontmatter con campos específicos y luego el cuerpo en Markdown con las instrucciones detalladas. Los campos de configuración incluyen `name` (identificador), `description` (propósito, usado en invocación automática), `model` (modelo preferido para este agente), `allowed-tools` (lista de herramientas habilitadas), `user-invocable` (si aparece en el picker `/agents`), y `disable-model-invocation` (si deshabilitar la invocación automática como tool).

El campo más crítico para entender la invocación automática es `description`. Cuando el agente principal recibe una tarea, el modelo evalúa todos los custom agents disponibles (sus descripciones) y decide si la tarea encaja mejor con alguno de ellos. Si hay match, lanza el custom agent como subagente automáticamente. Esto significa que si el `description` de tu agente `sdd-spec` dice algo como "Especialista en escritura de especificaciones funcionales para el ciclo SDD, úsame cuando se necesite crear o actualizar el archivo spec de un cambio", el orquestador puede invocar ese agente automáticamente cuando tú le digas "escribe el spec para el cambio user-auth". Pero también puedes invocarlo explícitamente con `/agent sdd-spec` o con `--agent sdd-spec` desde línea de comandos.

## Dónde Viven los Custom Agents y la Jerarquía de Prioridad

Los custom agents se descubren desde múltiples ubicaciones con una jerarquía clara: `~/.copilot/agents/` para el nivel de usuario (aplica a todos los repositorios), `.github/agents/` para el nivel de repositorio, el repositorio `.github` de la organización para el nivel organizacional, y plugins que pueden proveer sus propios agents. Esta jerarquía es muy importante para tu equipo porque te permite tener dos capas: una capa de agentes organizacionales compartidos (en el `.github` de la org, accesibles a todos los repos sin copiar archivos) y una capa de agentes específicos del proyecto (en `.github/agents/` del repo) que extienden o especializan los organizacionales.

En caso de conflicto de nombres, el nivel de usuario (home) sobreescribe al del repositorio, y el del repositorio sobreescribe al de la organización. Para tu framework, esto significa que puedes tener agentes SDD genéricos en la organización y agentes SDD especializados por proyecto en cada repositorio.

## Las Agent Skills: El Tercer Pilar

Además de los custom agents, Copilot CLI introduce Agent Skills, que permiten enseñarle a Copilot flujos de trabajo especializados mediante archivos skill en Markdown. Los skills cargan automáticamente cuando son relevantes y funcionan tanto en Copilot coding agent, Copilot CLI como en VS Code. Esta es la pieza que más se parece a los `SKILL.md` de ATL. Las skills son instrucciones procedurales que el agente (o subagente) carga en su contexto cuando el modelo determina que son relevantes para la tarea. La diferencia con los custom agents es conceptual: un **custom agent** es una identidad especializada con sus propias herramientas y modelo, mientras que una **skill** es un conjunto de instrucciones que cualquier agente puede cargar y seguir. Para tu caso práctico, los custom agents definen "quién es" cada subagente de tu pipeline SDD, y los skills definen "cómo hace su trabajo" ese subagente.

## El Modelo de Gasto: La Pregunta más Importante

Cada interacción con el agente consume del allowance de premium requests de tu plan respectivo. Pero la pregunta real es: cuando el orquestador lanza un subagente, ¿eso cuenta como una request adicional o es parte de la misma?

La respuesta, basada en el changelog técnico, es que **sí consume requests adicionales**. El comando `/usage` incluye el consumo de tokens de los sub-agentes, y las métricas de uso de sesión incluyen la actividad de subagentes. Esto significa que cuando el orquestador lanza `sdd-spec` y `sdd-design` en paralelo (Fleet mode), esas dos invocaciones de subagentes consumen requests del plan adicionales a la request del orquestador mismo. Fleet tiene las características de performance más altas en consumo de tokens (parallel subagents) pero el tiempo de ejecución de reloj más rápido para trabajo paralelizable.

Para equipos con Business ($19/usuario/mes) o Enterprise ($39/usuario/mes), el allowance de premium requests es sustancialmente mayor que en Pro, y el framework SDD que propongo está diseñado para ser eficiente: el orquestador tiene contexto mínimo, los subagentes tienen contexto fresco y enfocado, y Engram evita que los subagentes tengan que redescubrir contexto del codebase en cada fase. En la práctica, un ciclo completo SDD (explore → propose → spec + design en paralelo → tasks → apply → verify → archive) consumirá entre 8 y 12 premium requests dependiendo de la complejidad del cambio, lo cual es perfectamente razonable para trabajo de feature development real.

## AGENTS.md: La Instrucción Global que todo Copilot Lee

Copilot soporta el archivo `AGENTS.md` como archivo de instrucciones para el agente, incluyendo la capacidad de generar un archivo `AGENTS.md` inicial. Copilot descubre y carga automáticamente los archivos de instrucciones del agente que has definido en el contexto durante flujos de trabajo agentic, desde el workspace actual o globalmente desde todos los workspaces. Este `AGENTS.md` en la raíz del repositorio es el equivalente exacto al `copilot-instructions.md` del ejemplo de VS Code en ATL. Es el documento que "programa" al agente principal (el orquestador) con las reglas de comportamiento, los comandos disponibles, el mapeo de comandos a subagentes, y la política de Engram.

---

# PARTE 2 — Propuesta de Framework SDD para GitHub Copilot CLI, fiel a ATL + Engram

## Visión General de la Arquitectura

La arquitectura que propongo mapea directamente los conceptos de ATL al ecosistema nativo de Copilot CLI, aprovechando cada primitiva disponible en su rol más natural. El `AGENTS.md` actúa como orquestador siguiendo las mismas reglas delegate-only de ATL. Los custom agents en `.github/agents/` son los subagentes del pipeline SDD, cada uno con su propio contexto independiente. Los archivos de skill complementan las instrucciones de cada agente con procedimientos detallados. Engram (configurado como MCP server) es el almacén persistente de todos los artefactos, usando exactamente la misma convención de naming determinístico de ATL. El modo Fleet de Copilot habilita el paralelismo nativo para las fases spec+design. Y los hooks de Copilot CLI permiten inyección automática de contexto de Engram al inicio de cada subagente.

La estructura completa de archivos en el repositorio queda así:

```
mi-proyecto/
│
├── AGENTS.md                          ← Orquestador principal (equivalente a copilot-instructions.md)
│
├── .github/
│   └── agents/                        ← Custom agents del pipeline SDD
│       ├── sdd-init.agent.md
│       ├── sdd-explore.agent.md
│       ├── sdd-propose.agent.md
│       ├── sdd-spec.agent.md
│       ├── sdd-design.agent.md
│       ├── sdd-tasks.agent.md
│       ├── sdd-apply.agent.md
│       ├── sdd-verify.agent.md
│       ├── sdd-archive.agent.md
│       └── skill-registry.agent.md
│
├── .copilot/
│   ├── config                         ← Configuración de Copilot CLI (Engram MCP aquí)
│   ├── skills/                        ← Agent Skills con instrucciones procedurales
│   │   ├── _shared/
│   │   │   ├── engram-convention.md   ← Naming determinístico, recovery protocol
│   │   │   ├── tech-stack.md          ← Stack del equipo, convenciones, patrones
│   │   │   └── result-contract.md     ← Formato del envelope de retorno
│   │   ├── sdd-init.skill.md
│   │   ├── sdd-explore.skill.md
│   │   ├── sdd-propose.skill.md
│   │   ├── sdd-spec.skill.md
│   │   ├── sdd-design.skill.md
│   │   ├── sdd-tasks.skill.md
│   │   ├── sdd-apply.skill.md
│   │   ├── sdd-verify.skill.md
│   │   └── sdd-archive.skill.md
│   └── hooks/
│       └── subagent-start.sh          ← Hook que inyecta contexto Engram al inicio
│
└── .atl/
    └── skill-registry.md              ← Catálogo generado por sdd-init (igual que ATL)
```

## El `AGENTS.md`: El Orquestador Fiel a ATL

Este es el archivo más crítico del framework. Define al agente principal como un coordinador puro que nunca hace trabajo de fase, siempre delega, y mantiene contexto mínimo. Lo que sigue es el contenido completo propuesto:

```markdown
# SDD Orchestrator — GitHub Copilot CLI

Este archivo define el comportamiento del agente principal para el framework
de Spec Driven Development del equipo. Leer completamente antes de actuar.

## Principio Fundamental: Delegate-Only

Eres el ORQUESTADOR del pipeline SDD. Tu única responsabilidad es coordinar.
NUNCA ejecutas trabajo de fase directamente. SIEMPRE delegas a los subagentes
correspondientes vía custom agents.

### Lo que NUNCA haces tú directamente:
- Leer código fuente del repositorio para analizar
- Escribir especificaciones, proposals o documentos de diseño
- Escribir código de implementación
- Ejecutar tests o comandos de verificación
- Buscar o consultar Engram directamente (los subagentes lo hacen)

### Lo que SÍ haces tú:
- Trackear qué artefactos Engram existen para el cambio activo
- Lanzar los subagentes correctos con el contexto pre-resuelto
- Presentar resúmenes al usuario después de cada fase
- Pedir confirmación antes de proceder a la siguiente fase
- Sugerir SDD para features/refactors sustanciales

## Almacén de Artefactos: Engram (siempre)

Este framework usa Engram como único backend de artefactos.
Naming determinístico para todos los artefactos SDD:
```

title:     sdd/{change-name}/{artifact-type}
topic_key: sdd/{change-name}/{artifact-type}
type:      architecture
project:   {nombre detectado del proyecto}

```

Tipos de artefacto: explore, proposal, spec, design, tasks,
apply-progress, verify-report, archive-report
Init del proyecto: sdd-init/{project-name}

Recovery siempre en dos pasos:
1. mem_search("sdd/{change-name}/{type}", project: "{project}") → obtener ID
2. mem_get_observation(id) → contenido completo sin truncar

## Comandos SDD

- `/sdd-init` → Inicializa el proyecto en Engram, construye skill registry
- `/sdd-explore <topic>` → Investigación sin compromiso (no crea artefactos)
- `/sdd-new <change-name>` → Inicia cambio nuevo: explore → propose
- `/sdd-continue [change-name]` → Siguiente artefacto en la cadena
- `/sdd-ff [change-name]` → Fast-forward: propose → spec+design(paralelo) → tasks
- `/sdd-apply [change-name]` → Implementación con TDD
- `/sdd-verify [change-name]` → Validación con ejecución real de tests
- `/sdd-archive [change-name]` → Consolidación y cierre del cambio

## Mapeo Comando → Subagente

| Comando | Agent(s) invocado(s) |
|---------|----------------------|
| /sdd-init | sdd-init |
| /sdd-explore | sdd-explore |
| /sdd-new | sdd-explore → sdd-propose |
| /sdd-continue | siguiente necesario en DAG |
| /sdd-ff | sdd-propose → [sdd-spec ∥ sdd-design] → sdd-tasks |
| /sdd-apply | sdd-apply |
| /sdd-verify | sdd-verify |
| /sdd-archive | sdd-archive |

## Grafo de Dependencias (DAG)
```

proposal → [spec ∥ design] → tasks → apply → verify → archive

```

spec y design corren en PARALELO (Fleet mode) porque no dependen entre sí,
solo dependen del proposal.

## Reglas del Orquestador

1. NUNCA ejecutes trabajo de fase inline — siempre usa el custom agent
2. NUNCA leas código fuente directamente — los subagentes lo hacen
3. NUNCA invoques /sdd-ff, /sdd-continue, /sdd-new vía el agent tool —
   son meta-comandos que TÚ procesas lanzando Task calls individuales
4. Entre fases: muestra el resumen ejecutivo y pide confirmación al usuario
5. Mantén contexto MÍNIMO — referencia claves Engram, no contenidos
6. Cuando un subagente sugiere "ejecutar /sdd-verify", muéstraselo al
   usuario como sugerencia — no lo auto-ejecutes
7. Para /sdd-ff y fases paralelas, usa Fleet mode
8. Para /sdd-apply en autopilot, sugiere cambiar a Autopilot mode

## Skill Locations

Skills en `.copilot/skills/` del repositorio:
- sdd-init.skill.md, sdd-explore.skill.md, sdd-propose.skill.md
- sdd-spec.skill.md, sdd-design.skill.md, sdd-tasks.skill.md
- sdd-apply.skill.md, sdd-verify.skill.md, sdd-archive.skill.md
- _shared/engram-convention.md, _shared/tech-stack.md

Para cada fase: lee el skill correspondiente y pásaselo al subagente
como parte de su prompt inicial junto con el change-name y la clave Engram
del artefacto previo.

## Contrato de Resultado de Subagentes

Cada subagente retorna:
- **Status**: success | partial | blocked
- **Summary**: 1-3 oraciones de lo hecho
- **Artifacts**: clave(s) Engram escritas
- **Next**: próxima fase recomendada
- **Risks**: riesgos encontrados o "None"
```

## Los Custom Agents: Uno por Fase del Pipeline

Cada archivo `.agent.md` en `.github/agents/` define un subagente del pipeline. El formato es YAML frontmatter seguido de instrucciones en Markdown. Aquí el diseño de cada uno:

**`sdd-explore.agent.md`**: Este agente es el investigador del sistema. Su `description` debe decir que es un especialista en exploración de codebase para el ciclo SDD, y debe invocarse cuando se necesite entender un área del código antes de proponer cambios. Su cuerpo de instrucciones le indica que cargue `.copilot/skills/sdd-explore.skill.md` y `.copilot/skills/_shared/engram-convention.md` al inicio, que busque en Engram cualquier exploración previa del mismo tema para no duplicar trabajo, que realice su análisis del codebase, y que guarde el resultado con `mem_save` siguiendo la convención `sdd/{change-name}/explore`. Tiene acceso completo a herramientas de lectura de archivos pero no de escritura de código.

**`sdd-propose.agent.md`**: El agente de propuesta transforma la exploración en una propuesta formal con scope, approach y rollback plan. Recupera el artefacto `sdd/{change-name}/explore` de Engram, construye el proposal, y lo persiste como `sdd/{change-name}/proposal`. Es el primer agente que produce un artefacto "oficial" del cambio.

**`sdd-spec.agent.md`** y **`sdd-design.agent.md`**: Estos dos son los candidatos para ejecución en paralelo via Fleet. El spec agent escribe los requerimientos funcionales y los escenarios de prueba en formato Gherkin o similar, recuperando el proposal de Engram. El design agent escribe el diseño técnico: arquitectura de componentes, decisiones de tecnología, diagramas de flujo. Ambos solo necesitan el proposal para operar, por lo tanto no tienen dependencia entre sí y pueden correr simultáneamente. Esto es exactamente el paralelismo que describe ATL y que Fleet mode en Copilot CLI habilita nativamente.

**`sdd-tasks.agent.md`**: El planner necesita tanto el spec como el design para generar su lista de tareas atomizadas y ordenadas. Recupera ambos de Engram y produce una checklist priorizada con criterios de aceptación para cada tarea, persistida como `sdd/{change-name}/tasks`.

**`sdd-apply.agent.md`**: El implementador tiene acceso completo a herramientas de escritura de código. Recupera los tasks de Engram, implementa siguiendo el flujo TDD que el equipo use (definido en `_shared/tech-stack.md`), y actualiza progresivamente `sdd/{change-name}/apply-progress` en Engram. Este es el agente ideal para correr en Autopilot mode.

**`sdd-verify.agent.md`**: El verificador ejecuta los tests reales del proyecto, revisa la matriz de compliance contra el spec de Engram, y produce un reporte detallado. No improvisa criterios: usa el spec que ya fue aprobado como fuente de verdad.

**`sdd-archive.agent.md`**: El archivador consolida todos los artefactos, escribe el reporte final del cambio en Engram, y puede disparar la creación de un GitHub issue o PR usando el MCP de GitHub que viene built-in en Copilot CLI.

## El Hook de Inicio: Contexto Automático de Engram

Una de las ventajas de Copilot CLI sobre otros entornos es el sistema de hooks. El hook `subagentStart` se dispara cada vez que se levanta un subagente, y en él puedes ejecutar un script que recupera contexto de Engram e inyecta información relevante. El archivo `.copilot/hooks/subagent-start.sh` puede consultar `engram context` (el CLI de Engram) para obtener las memorias recientes del proyecto y pasarlas al subagente como contexto adicional, asegurando que cada agente arranca informado sin que el orquestador tenga que cargar ese contexto en su propia ventana.

## Engram como MCP Server en Copilot CLI

La configuración de Engram en Copilot CLI es directa. En el archivo `~/.copilot/config` (o equivalente de proyecto), se añade Engram como MCP server:

```json
{
  "mcpServers": {
    "engram": {
      "command": "engram",
      "args": ["mcp"]
    }
  }
}
```

Una vez configurado, todos los subagentes tienen acceso a los 10 tools de Engram (`mem_save`, `mem_search`, `mem_get_observation`, `mem_context`, etc.) como herramientas nativas dentro de su loop de ejecución. Esto es fundamental: no necesitas que el orquestador sea el intermediario de Engram porque cada subagente puede leer y escribir sus propios artefactos directamente, siguiendo la convención de naming que el `AGENTS.md` establece.

## El Skill Registry: Generado por `sdd-init`

El agente `sdd-init` tiene una responsabilidad especial: al ejecutarse por primera vez en un proyecto, escanea todos los custom agents disponibles en `.github/agents/` y todos los skills en `.copilot/skills/`, lee sus descripciones y propósitos, y escribe un catálogo en `.atl/skill-registry.md`. Este catálogo es lo que el orquestador referencia cuando construye el prompt de lanzamiento de cada subagente, pasándole los paths exactos de sus skills en lugar de tener que descubrirlos él mismo en cada sesión. Además, `sdd-init` crea la entrada inicial en Engram para el proyecto: `mem_save` con `title: "sdd-init/{project-name}"` capturando la información fundamental del proyecto, stack, convenciones y equipo.

## El Flujo de Trabajo Completo en Práctica

Imagina que el equipo va a desarrollar un nuevo sistema de autenticación. El desarrollador abre su terminal y ejecuta `copilot`, lo que inicia una sesión de Copilot CLI. El `AGENTS.md` ya está en el repositorio y Copilot lo carga automáticamente, configurando el orquestador con todas las reglas definidas.

El desarrollador escribe `/sdd-explore user-authentication`. El orquestador lee esto como un meta-comando, toma el change-name `user-authentication`, construye el prompt de lanzamiento para `sdd-explore` incluyendo el skill correspondiente y la clave Engram objetivo, y lanza el custom agent `sdd-explore.agent.md` como subagente. Este subagente arranca con su propia ventana de contexto fresca, carga el skill, busca en Engram si hay exploraciones previas sobre autenticación, escanea el codebase actual, y produce un análisis estructurado que persiste en Engram como `sdd/user-authentication/explore`. Retorna el envelope con status success, summary de 2 oraciones, y artifacts. El orquestador recibe el envelope, extrae el summary, lo presenta al usuario, y pregunta si desea continuar con la propuesta.

El usuario confirma, y el orquestador ejecuta `/sdd-new user-authentication`, que dispara `sdd-propose`. Este agente recupera el explore de Engram en dos pasos (search para ID, get_observation para contenido completo), construye el proposal con scope, approach y rollback plan, y lo persiste como `sdd/user-authentication/proposal`. El orquestador presenta el summary y pregunta si ejecutar `/sdd-ff`.

Cuando el usuario aprueba el fast-forward, el orquestador entra en Fleet mode y lanza `sdd-spec` y `sdd-design` en paralelo. Ambos recuperan el proposal de Engram independientemente, trabajan en sus respectivos artefactos simultáneamente, y persisten `sdd/user-authentication/spec` y `sdd/user-authentication/design`. El orquestador espera que ambos terminen, sintetiza los dos envelopes, y sin pausa lanza `sdd-tasks` (que ahora puede recuperar ambos artefactos). Con los tasks generados, el pipeline de planificación está completo.

Para la implementación, el usuario puede cambiar a Autopilot mode y ejecutar `/sdd-apply user-authentication`. El agente `sdd-apply` en Autopilot lee los tasks de Engram y comienza a implementar sin interrupciones, actualizando `apply-progress` periódicamente. Después, `sdd-verify` corre los tests reales y produce el verify-report. Finalmente, `sdd-archive` cierra el ciclo y puede usar el MCP de GitHub integrado para crear el PR directamente desde la CLI.

Todo este proceso deja una trazabilidad completa en Engram, que gracias al Git Sync de Engram puede commitearse al repositorio para que el resto del equipo la tenga disponible en sus propias sesiones.

## Consideraciones Finales sobre Costos y Eficiencia

Dado que cada subagente consume premium requests, la estrategia de diseño del framework prioriza la eficiencia: el orquestador tiene contexto mínimo (gasta pocos tokens por turno), los subagentes tienen instrucciones precisas vía skills (no pierden tokens en "exploración" de qué hacer), Engram evita que los subagentes tengan que redescubrir el codebase (no repiten trabajo de lectura de archivos), y el paralelismo de Fleet para spec+design reduce el tiempo de wall-clock aunque use más requests totales. Para equipos con Business o Enterprise plan, este modelo es completamente sostenible como flujo de trabajo diario. Para equipos con Pro ($10/mes), tiene sentido usar el framework completo para features significativas y flujos más simples para cambios menores.

Lo que estás construyendo, en esencia, es un proceso de ingeniería de software que usa IA de forma disciplinada: primero entendés, luego proponés, luego especificás, luego diseñás, luego planificás, luego implementás, luego verificás. La IA amplifica cada paso, pero el proceso en sí es lo que garantiza calidad y consistencia en el equipo. Eso es exactamente lo que Agent Teams Lite propone, y es exactamente lo que este framework replica para Copilot CLI.

---

# Preguntas y Respuestas que quedaron de lo anterior

## Preguntas

1. Confirmame si efectivamente los subagents lanzados con su propia ventana de contexto , si consumen mas requests ? Tengo entendido GithubCopilot se gasta es por requests, no por tokens. Podrias confirmar o explicar bien esto ? Si es de otra manera, explicalo completamente .
2. En cuanto a la arquitecutra propuesta, no me queda claro porque por cada agent hay un equivalente en una skill ? Por ejemplo, se tiene sdd-explore.agent.md y a su vez sdd-explore.skill.md . Cual es la ventjaa de esto ? En que se diferencian ? Si deberia de ser asi ?
3. Otra cosa, lo edl hook para que es ? Si es necesario inyectar en el prompt hacia cada subagente lo de Engram ? Cada agente no tiene pues como la capacidad de consultar a Engram ? O como lo hace ATL ?

## Respuestas

### Respuesta 1 — El modelo de gasto: requests, no tokens, y cómo funciona con subagentes

Tu intuición era correcta en la dirección correcta, pero la realidad tiene un matiz importantísimo que cambia completamente el análisis de costo del framework.

Para features agenticas, solo los prompts que tú envías cuentan como premium requests; las acciones que Copilot toma de manera autónoma para completar tu tarea, como las tool calls, no cuentan. Esto es la clave de todo. Cuando el orquestador lanza un subagente, eso es una **tool call** interna del sistema, no un nuevo prompt tuyo. Por lo tanto, no consume un premium request adicional.

Para entenderlo bien, hay que comprender qué cuenta exactamente como "un request" en el modelo de Copilot. Un premium request se genera en el momento que tú, el humano, envías un mensaje. Lo que pase a partir de ahí — cuántas tool calls haga el agente, cuántos subagentes lance, cuántos archivos lea, cuántas veces consulte Engram — todo eso es trabajo autónomo del agente y no genera requests adicionales. Técnicamente puedes comprobarlo en este issue de VS Code donde un usuario descubrió (reportándolo como bug) que los subagentes y las tool calls no consumen ningún "request"; el costo se calcula en base al modelo inicial usado. Combinando esto correctamente, es posible tener uso casi ilimitado de modelos premium costosos como Opus 4.5, que normalmente costaría 3 premium requests, porque el request inicial lo toma el modelo "gratuito" y el subagente que usa el modelo caro corre sin costo adicional.

Esto también te da un insight sobre la estrategia de diseño de tu framework: el modelo que asignes al orquestador (el agente principal que vive en `AGENTS.md`) es el que determina el costo de cada interacción tuya, porque es el que recibe tus prompts directamente. Los subagentes SDD que lanzan las fases del pipeline pueden correr con modelos más potentes sin costo adicional por subagente, dado que son invocados como tool calls desde el orquestador, no como nuevos prompts tuyos.

Cada modelo tiene un multiplicador de premium request basado en su complejidad y uso de recursos. Por ejemplo, usar Claude Opus 4.5 en Copilot Chat con un multiplicador de 3x hace que una interacción cuente como 3 premium requests. Los modelos GPT-4.1 y GPT-4o son los modelos incluidos y no consumen premium requests si estás en un plan de pago.

Entonces la economía real de tu framework SDD es esta: en un ciclo completo, si haces seis interacciones contigo (explore, propose, ff, apply, verify, archive), consumes seis premium requests multiplicados por el multiplicador del modelo de tu orquestador. Todo el trabajo de los subagentes, incluidas todas las lecturas de Engram, escrituras, análisis de código, implementación, es gratuito en términos de requests. Esto hace que el framework sea mucho más económico de lo que yo había estimado en el informe anterior, y elimina la preocupación por el paralelismo en Fleet mode: correr spec y design en paralelo no cuesta el doble que correrlos en secuencia.

### Respuesta 2 — ¿Por qué hay un `.agent.md` Y un `.skill.md` por fase? ¿Es redundante?

Es una observación aguda y la respuesta corta es: sí, en la propuesta anterior había una redundancia innecesaria. Déjame explicar la diferencia conceptual real entre los dos, y luego te digo cuál es el diseño correcto para tu caso.

Un **custom agent** (`.agent.md`) es una **identidad** persistente con características fijas: tiene un nombre, una descripción que el orquestador usa para decidir cuándo invocarlo automáticamente, un modelo preferido, y una lista de herramientas habilitadas. El cuerpo del archivo contiene sus instrucciones de comportamiento generales, lo que lo define como "quién es". Un agente vive más allá de un solo ciclo SDD; es una entidad reutilizable.

Una **skill** (`.skill.md`) en el contexto original de ATL es un **procedimiento de trabajo** detallado y cargado bajo demanda. En ATL, cada SKILL.md contiene las instrucciones paso a paso de qué hacer, cómo recuperar el contexto de Engram para esa fase, qué criterios de calidad aplicar, y el formato exacto de retorno. La skill no define una identidad; define un protocolo de ejecución.

La distinción tiene sentido pleno en Claude Code, donde las skills son archivos que el orquestador pasa explícitamente en el prompt de lanzamiento del subagente via `Task tool`. El subagente nace sin identidad previa, lee la skill, y sabe qué hacer. En Copilot CLI, los custom agents ya tienen sus instrucciones dentro del `.agent.md` mismo. Si además les pasas una skill por separado, estás duplicando contenido: el agente tiene en su frontmatter+body todo lo que necesita, y la skill sería básicamente lo mismo escrito dos veces.

La solución correcta para Copilot CLI es colapsar ambos en uno solo: el `.agent.md` contiene tanto la identidad del agente (frontmatter con nombre, descripción, modelo, herramientas) como el procedimiento detallado de trabajo (el body en Markdown, que es exactamente lo que sería el SKILL.md de ATL). La carpeta `_shared/` sí tiene sentido mantenerla, pero como archivos de convenciones comunes que todos los agentes referencian en su body, no como skills separadas.

La estructura simplificada correcta es esta:

```
.github/
└── agents/
    ├── sdd-init.agent.md        ← identidad + procedimiento completo
    ├── sdd-explore.agent.md
    ├── sdd-propose.agent.md
    ├── sdd-spec.agent.md
    ├── sdd-design.agent.md
    ├── sdd-tasks.agent.md
    ├── sdd-apply.agent.md
    ├── sdd-verify.agent.md
    └── sdd-archive.agent.md

.copilot/
└── shared/
    ├── engram-convention.md     ← naming determinístico, recuperación en 2 pasos
    ├── tech-stack.md            ← stack del equipo, convenciones, patrones
    └── result-contract.md       ← formato del envelope de retorno
```

Cada `.agent.md` referencia los archivos de `_shared/` con algo como `See .copilot/shared/engram-convention.md for artifact naming rules` en su body, pero el procedimiento completo de qué hacer y cómo hacerlo está dentro del `.agent.md` mismo. Eliminás la capa de `.copilot/skills/` por completo porque era redundante con los agents.

### Respuesta 3 — ¿Los hooks son necesarios para inyectar contexto de Engram? ¿Cómo lo hace ATL?

Esta es la pregunta más reveladora de las tres porque toca un malentendido de diseño de la propuesta anterior. La respuesta corta es: no, el hook no es necesario para Engram, y de hecho es un anti-patrón. Déjame explicar por qué.

En ATL, Engram está configurado como un MCP server. Esto significa que todos los tools de Engram (`mem_save`, `mem_search`, `mem_get_observation`, etc.) son herramientas nativas disponibles en el toolset de cada agente, exactamente igual que "leer un archivo" o "ejecutar un comando". Cuando el agente de `sdd-spec` empieza a trabajar, no necesita que nadie le "inyecte" el contexto de Engram porque él mismo puede simplemente llamar `mem_search("sdd/{change-name}/proposal")` como una de sus primeras acciones, exactamente como si abriera un archivo. Eso es precisamente la elegancia del diseño de Engram como MCP: cada subagente es autónomo en la recuperación de su contexto porque tiene las herramientas de acceso directo.

Lo que el orquestador sí hace en ATL (y lo que el `AGENTS.md` debe instruir) es pasarle al subagente el `change-name` y el `artifact-type` que necesita recuperar. No el contenido del artefacto, solo las claves necesarias para que el subagente pueda buscarlo. Es una diferencia crucial: el orquestador no carga contenido en su contexto (eso lo haría pesado y costoso), solo trackea metadata, y el subagente usa esa metadata para recuperar el contenido directamente de Engram con su propio contexto fresco.

El hook que propuse era un intento de "pre-inyectar" contexto que los subagentes pueden buscar ellos mismos. Era innecesario, añadía complejidad, y rompía el principio de que cada subagente tiene contexto fresco e independiente. La única situación donde un hook de inicio tiene valor real es para cosas que el agente no puede hacer por sí mismo (por ejemplo, registrar la sesión en un sistema externo antes de que empiece a trabajar), no para proveer contexto que el agente puede recuperar con sus propias herramientas.

Entonces el diseño correcto, fiel a ATL, es este: Engram configurado como MCP server en Copilot CLI, cada subagente tiene acceso a todos los MCP tools de Engram como herramientas nativas, el orquestador solo pasa `change-name` como parámetro en el prompt de lanzamiento, y cada agente ejecuta su propio recovery de dos pasos al inicio de su trabajo siguiendo la convención de naming definida en `_shared/engram-convention.md`.

En el body de cada `.agent.md`, las primeras instrucciones son siempre: recupera el artefacto previo que necesito con `mem_search` y `mem_get_observation`, usando el change-name que te pasó el orquestador. Eso es todo. No hay hooks, no hay inyección externa, no hay orquestador que cargue contenido. Cada subagente es autónomo, tiene contexto fresco, y sabe exactamente cómo encontrar lo que necesita porque la convención de naming es determinística y está documentada en el shared.

---

# Ver siguiente Seccion para hablar mas de costos