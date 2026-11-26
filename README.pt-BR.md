<div align="center">

# 🎯 piercer_hitchhunter

**Detector de hitch e caçador de culpados para servidores FiveM, com NUI no jogo, painel web opcional e forense de queda.**

Captura cada `network thread hitch warning` (e `server thread hitch warning`), tira um retrato do servidor naquele exato momento e ranqueia os resources mais prováveis de serem a causa, usando entidades por criador, queries lentas, starts/stops recentes e o profiler nativo. Funciona em **qualquer base e framework**.

![FiveM](https://img.shields.io/badge/FiveM-resource-F40552?style=for-the-badge)
![Frameworks](https://img.shields.io/badge/vRP%20%C2%B7%20Creative%20%C2%B7%20ESX%20%C2%B7%20QBCore%20%C2%B7%20Qbox%20%C2%B7%20TNet%20%C2%B7%20standalone-2b2b2b?style=for-the-badge)
![Lua](https://img.shields.io/badge/Lua-5.4-2C2D72?style=for-the-badge&logo=lua&logoColor=white)
![UI](https://img.shields.io/badge/NUI-PT--BR%20%2F%20EN--US-black?style=for-the-badge)
[![Discord](https://img.shields.io/badge/Discord-entrar-5865F2?style=for-the-badge&logo=discord&logoColor=white)](https://discord.gg/framezerodevelopment)

[![Read in English](https://img.shields.io/badge/Read%20in%20English-5865F2?style=for-the-badge&logo=googletranslate&logoColor=white)](README.md)

</div>

---

## 🎯 Objetivo & Recursos

O `network thread hitch warning` significa que a thread de rede do servidor ficou bloqueada por centenas de milissegundos. Raramente é "um resource spammando o aviso": é algum resource fazendo algo pesado ou enviando coisa demais **naquele instante**, e o console nunca diz qual.

Causas típicas que a ferramenta ajuda a restringir:
- **Enxurrada de entidades:** um script criando peds, veículos ou objetos em massa (OneSync).
- **Queries lentas:** SQL síncrono ou pesado bloqueando a thread.
- **Start/stop pesado:** resources sendo iniciados ou reiniciados em horário de pico.
- **Handlers e ticks pesados de CPU:** descobertos com o profiler nativo.

O **piercer_hitchhunter** registra cada hitch como um incidente com contexto e uma lista ranqueada de suspeitos, para você saber onde olhar primeiro.

- 🧩 **Auto-Adaptação via framezero_bridge**: permissões e notificações funcionam em qualquer base (vRP tradicional, vRPex, Creative v3/v5/Network, TNet, QBCore, Qbox, ESX, OxCore ou Standalone ACE).
- 🔎 **Ranking de Suspeitos**: entidades por resource criador (`GetEntityScript`) e o crescimento delas, queries lentas, starts/stops recentes, mais o tempo real de CPU do profiler quando disponível.
- 🖥️ **NUI Compacta**: abra no jogo com `/hitchhunter`, bilíngue (alternância PT-BR e EN-US) com a escolha lembrada por jogador.
- 🌐 **Painel Web Opcional**: dê duplo clique em `tools/start.bat` e acompanhe o servidor pelo navegador, até com ele fora do ar. Sem instalar nada, sem API, sem token.
- 💥 **Forense de Queda**: o estado é salvo a cada ~10s; se o próximo boot encontrar um encerramento não limpo, é criado um incidente `queda?` com os últimos suspeitos conhecidos.
- ⚙️ **Ações Remotas**: snapshot, profiler, ignorar falsos positivos, anotações, resolver e reinício opcional de resource, idênticas na NUI e no painel web.

---

## 🚀 Instalação

1. Certifique-se de que a resource **`framezero_bridge`** está instalada em sua base:
   ```
   resources/[framezero-dev-scripts]/framezero_bridge
   ```
2. Coloque a pasta `piercer_hitchhunter` no diretório `resources/`:
   ```
   resources/[framezero-dev-scripts]/piercer_hitchhunter
   ```
3. Adicione ao seu `server.cfg` (garantindo que a bridge inicie primeiro):
   ```cfg
   ensure framezero_bridge
   ensure piercer_hitchhunter
   ```
4. Dê permissão a quem for usar. Qualquer uma destas basta (veja `Config.Permissions`):
   - permissão/grupo da sua base (ex.: permissão da vRP, grupo do QBCore/ESX) listado em `bridge`;
   - ACE: `add_ace group.admin piercer_hitchhunter.use allow`;
   - identificadores fixos (`license:...`, `discord:...`).

Não há mais nada para configurar. Ele começa a registrar hitches imediatamente.

---

## ⌨️ Comandos

| Comando | Descrição |
|---|---|
| `/hitchhunter` | Abre ou fecha a NUI no jogo (`Esc` também fecha). Exige permissão. |
| `hitch_profile` | Console do servidor: grava o profiler nativo e anexa o resultado ao último incidente. |
| `hitch_status` | Console do servidor: mostra quantos incidentes, amostras e queries lentas estão em memória. |

---

## 🧰 Ações

Disponíveis na NUI do jogo e no painel web:

| Ação | O que faz |
|---|---|
| **Snapshot** | Tira uma amostra agora: jogadores, entidades e os resources que mais criam. |
| **Gravar profiler** | Grava o profiler nativo e anexa o detalhamento de CPU ao último incidente. |
| **Exportar** / **Baixar JSON** | No jogo salva `data/report-*.json`; no web baixa direto no navegador. |
| **Limpar** | Apaga todos os incidentes (pede um segundo clique). |
| **Ignorar** (por suspeito) | Tira um resource das listas de suspeitos, útil para falsos positivos fixos como `oxmysql`. Desfaça pelos chips "Ignorados". |
| **Anotar** / **Marcar resolvido** | Registra a causa encontrada e deixa o incidente apagado na lista. |
| **Reiniciar** (por suspeito) | Dá restart nesse resource. **Desligado por padrão**, veja abaixo. |

> `Reiniciar resource` só aparece com `Config.Actions.restartResource = true` e **reinicia o resource de verdade**. Tudo em `Config.Actions.protected` (bridge, oxmysql, monitor...) e o próprio hitchhunter nunca podem ser reiniciados por aqui.

---

## 🌐 Painel Web

Dê duplo clique em **`tools/start.bat`**. Ele usa o PowerShell que já vem no Windows (nada para instalar), abre `http://localhost:8787/` e atualiza a cada 5s.

**Como as ações chegam ao servidor, sem API exposta no FiveM:** o painel grava o pedido em `data/commands.json`; o resource lê a fila a cada ~2s, executa só ações da whitelist com argumentos validados, e responde em `data/results.json`, que o painel mostra. Pedidos com mais de 60s são descartados, para um comando antigo não disparar de surpresa depois de um reboot.

- Roda na mesma máquina do servidor FiveM (ou numa pasta compartilhada com o mesmo relógio).
- Só aceita conexões locais por padrão. As ações exigem o cabeçalho `X-Hitch` e origem `localhost`, o que impede que outras páginas abertas no seu navegador as disparem.
- Para liberar na rede, rode `start.bat -Bind +` com o PowerShell como Administrador. Nesse modo as **ações** exigem uma chave aleatória mostrada na janela do `start.bat` (a leitura continua aberta, então só faça isso numa rede confiável).
- Outra porta: `start.bat -Port 8788`.
- Host sem acesso ao disco? Baixe a pasta `data/` e rode `start.bat -DataFile "C:\caminho\incidents.json"`. Sem o resource lendo a fila, as ações não terão efeito.
- Um card **Servidor** mostra `online`, `encerrado` ou **`sem sinal há X`**, para você distinguir uma queda de um reinício normal.

---

## 💥 Forense de Queda

A NUI do jogo some junto com um servidor que caiu, mas os dados ficam em disco:

- O resource salva `data/last_state.json` a cada ~10s. Ele só ganha a marca `clean` em um encerramento normal (resource parado ou desligamento/reinício do txAdmin).
- No próximo boot, se a execução anterior **não** terminou de forma limpa, é criado um incidente **`queda?`** com suspeitos calculados a partir do último estado salvo (entidades por resource, queries lentas, resources recém-iniciados).
- Reinícios normais pelo txAdmin e `restart piercer_hitchhunter` contam como encerramento limpo e **não** geram o incidente. Desligue o recurso com `Config.CrashDetection = false`.
- É uma heurística. O estado pode ter até ~10s de defasagem, então os suspeitos são uma pista do que acontecia logo antes da queda, não uma causa comprovada. Um `quit` manual fora do txAdmin pode ser lido como queda.

---

## ⚙️ Configuração

O arquivo `config.lua` permite personalização completa:

- `Language`: idioma das mensagens do servidor (notificações e Discord): `pt-BR` ou `en-US`. A NUI tem seu próprio seletor PT-BR / EN-US.
- `Permissions`: `bridge` (permissões/grupos/jobs da base resolvidos pelo framezero_bridge), `ace` e `identifiers` fixos.
- `Actions`: `restartResource` (desligado por padrão), resources `protected` e o `commandTtl` / `pollMs` dos comandos.
- `MinHitchMs`, `MergeWindow`: ignoram hitches pequenos e juntam os consecutivos num único incidente.
- `SampleInterval`, `SampleHistory`, `MaxEntitiesPerSample`, `ContextSeconds`: como o servidor é amostrado.
- `Profiler`: gravação automática após um hitch (`frames`, `cooldown`, `outputFile`).
- `CrashDetection`: cria o incidente `queda?` após um encerramento não limpo.
- `Discord`: alerta opcional por webhook para hitches graves.

---

## 🔬 Como funciona

1. Escuta o console do servidor (`RegisterConsoleListener`) e interpreta cada aviso de hitch. Hitches consecutivos dentro da janela de agrupamento viram um incidente.
2. Amostra o servidor a cada 10s: jogadores, peds/veículos/objetos e **entidades por resource criador**. Também acompanha as linhas de query lenta impressas pelo oxmysql e os starts/stops de resources.
3. Quando um hitch acontece, monta o ranking de suspeitos. Se o profiler estiver ligado, ele grava automaticamente e mescla o tempo de CPU no ranking (`profiler+heurística`).
4. Tudo fica em `data/`, que alimenta tanto a NUI quanto o painel web.

---

## ⚠️ Limitações

- Sem o profiler, o ranking é **heurístico**: aponta suspeitos com evidências, não prova a causa.
- Um resource Lua não enxerga handlers de eventos de outros resources, então esse tipo de causa só aparece se o profiler pegar o momento.
- Os comandos `profiler record` / `profiler saveJSON` e o formato do JSON dependem da build do seu servidor. Se o ranking do profiler vier vazio, ajuste `server/profiler.lua` e `Config.Profiler.outputFile`.
- O profiler consome CPU, então só roda em janelas curtas com `cooldown` de 120s por padrão.
- O painel web é feito para Windows (PowerShell). Em host Linux, use a NUI do jogo ou baixe o `data/incidents.json` e rode o `start.bat` num PC Windows.

---

## 📋 Suporte

Feito para tornar a caça a hitches em servidores FiveM rápida e baseada em evidências. Dúvidas ou sugestões? Entre no nosso Discord: https://discord.gg/framezerodevelopment
