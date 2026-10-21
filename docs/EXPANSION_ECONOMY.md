# Etapa 3 — expansão e economia (0.3.0-expansion-economy)

Base: `f8c78e00797540a66770e152bb8a6ecd8b2fb3a6`, branch `main`.

## Como jogar esta etapa

1. Escolha terra livre e funde sua capital.
2. Veja tropas, capacidade, geração de tropas, ouro e geração de ouro no painel.
3. Escolha 10/25/35/50/75% e confira o envio previsto.
4. Toque numa célula neutra adjacente ao seu território e pressione **Expandir**.
5. A fronteira avança progressivamente a partir da célula escolhida. Acompanhe
   tropas comprometidas e células conquistadas no painel.

O envio mostrado é baseado no último estado recebido. O servidor calcula a
quantidade definitiva no momento em que recebe o comando, por isso pode haver
diferença se um tick de geração ocorrer durante o trânsito da mensagem. O retorno
do comando informa a quantidade efetivamente enviada.

O cliente não decide saldo, propriedade, custo ou quantidade final. O percentual é
validado por lista explícita. Cada comando possui número sequencial para impedir
que uma repetição gaste tropas novamente, mesmo após encerrar a ordem anterior.

## Balanceamento inicial centralizado em Config

| Regra | Valor |
| --- | --- |
| Tropas iniciais | 100 |
| Ouro inicial | 50 |
| Capacidade | 150 + 25 por célula |
| Tropas por segundo | 3 + 1 por célula |
| Ouro por segundo | 1 + 0,2 por célula |
| Custo de terra neutra | 10 tropas/célula |
| Limite por ordem | 24 células |
| Avanço | Até 2 células por pulso de 0,25 s |
| Economia | Um lote a cada segundo |

Com uma capital: capacidade 175, +4 tropas/s, +1,2 ouro/s. O ouro é acumulado para
construções futuras; ainda não existe compra nesta etapa. O teto técnico de ouro é
1 trilhão. Todo estado continua sendo da partida atual, sem persistência entre sessões.

## Autoridade e invariantes

- `EconomyService` inicializa recursos, recalcula taxas pela área e processa um lote
  de nações por tick. Não varre células para calcular renda.
- `ExpansionService` mantém uma ordem por nação, usando uma fila limitada de
  vizinhos terrestres a partir do alvo. Não há rotina/coroutine individual por ordem.
- `NationService` continua dono das células, conjunto de território e contagem.
  A fronteira é atualizada apenas na célula alterada e seus vizinhos.
- `MatchService` executa expansão e economia no único agendador do servidor,
  publicando um delta por lote. Alterações exclusivamente econômicas não invalidam
  blocos do mapa.
- `CommandService` permite `Expand` com ID da célula e percentual. Identidade vem
  do Player, e validação ocorre novamente no pulso antes de cada conquista.

O envio é descontado e fica comprometido com a ordem. Cada célula conquistada
consome 10 tropas. A sobra é devolvida ao terminar por falta de orçamento, limite
por ordem ou ausência de caminho neutro. Capacidade inclui tropas em reserva e
comprometidas; a regeneração não duplica o orçamento reservado. A devolução respeita
o limite militar, inclusive se futuramente a capacidade puder diminuir.

Água, terra distante, terra própria e inimigos não podem ser alvos de expansão
neutra. Não há salto entre ilhas ou conquista de país inteiro. Se duas ordens miram
o mesmo alvo ainda livre, uma vence a disputa no pulso e a outra devolve o envio.
A prioridade entre ordens ativas gira por pulso. Não há yield entre validar,
descontar e atualizar propriedade.

Ao sair: a ordem é descartada, a nação removida e suas células liberadas. Recursos
da sessão encerrada não são transferidos para uma nova sessão.

O agendador usa tempo decorrido, com limite de 5 s de economia e até 4 pulsos de
expansão por chamada após uma interrupção longa, evitando recuperação sem limite.

## Interface e visualização

`StrategyHud` separa a composição visual do transporte e da lógica de seleção.
O painel fica embaixo em retrato e à direita em paisagem larga. Em áreas baixas,
seus controles têm rolagem. Os percentuais mantêm alvos de toque de pelo menos
44 px nos tamanhos de tela testados. Zoom máximo passou a 24×, com foco da capital
em pelo menos 12×, para facilitar escolha de células. A seleção acompanha o tamanho
da célula quando ampliada. Nomes e tropas sobre capitais só aparecem perto.

O mapa permanece em ScreenGui; não foram adicionados Parts, física ou BillboardGuis
por célula. Os serviços antigos BotService, TerritoryService, TroopService e Remotes
continuam intactos e sem execução. ExpansionService substitui a função de expansão
legada na arquitetura ativa, sem reativar seus loops.

## Verificação

`python3 tools/test_lua.py` passou:

- Sintaxe dos 16 módulos atuais.
- 214 verificações de expansão/economia, incluindo saldo, percentuais, fronteira,
  capacidade, concorrência, devolução, saída, repetição de pedido e ilha isolada.
- 48 verificações da geometria do HUD em seis áreas úteis de telas.
- 29 verificações do fluxo real de controllers/gateway/serviços com transporte e
  temporizadores simulados, incluindo percentuais, preview, débito, conquista e renda.
- Regressões anteriores: 178.199 verificações de mapa e 25.941 de nações/réplica.

Esses testes não executam o motor gráfico Roblox. Pendente de validação real:
toques e pinça em iPhone/iPad, fluidez durante expansão, visual com gráficos mínimos
e máximos, e disputa com dois clientes Roblox. O painel deve exibir
`0.3.0-expansion-economy`.

## Infraestrutura e próximos passos

`default.project.json` e ambos os workflows permaneceram idênticos à base. O fluxo
usado continua `.github/workflows/publish-roblox.yml`, cujo blob é
`49424381fa2dee049925d5229511c27e031158b5`. Nenhum ID, secret ou mecanismo de
autenticação/publicação foi alterado. Build e publicação devem ser confirmados no
workflow após o avanço da main.

Próxima etapa: combate, conquista de células inimigas, mudança de capital e
eliminação. Bots e construções ainda não estão ativos.
