# Etapa 2 — nações e capitais (0.2.0-nations)

Registro histórico. Estado atual: [Etapa 3 — expansão e economia](EXPANSION_ECONOMY.md).

Base: `58ea2106072e5aecaa7d1bdf46d5417345fae714`, branch `main`.

## Fluxo disponível

1. Entrar como observador e sincronizar as nações existentes.
2. Arrastar/ampliar o mapa e tocar em terra livre.
3. Conferir a célula destacada e tocar em **Fundar capital aqui**.
4. O servidor valida e reserva uma célula, cria a nação e replica a mudança.
5. Ver a célula colorida e a estrela da capital. **Minha capital** reenquadra nela.

O nome vem do Player no servidor; a cor é escolhida entre as menos utilizadas da
paleta configurada. Os nomes aparecem ao aproximar o zoom. A posição lógica é uma
única célula: o tamanho da estrela facilita visualização e não aumenta território.
O HUD mostra versão, número de nações, células próprias e percentual de terra.

## Responsabilidades

- `NationService`: propriedade, capital, contagem, cores, saída e estado da partida.
- `CommandService`: comandos permitidos, limitação de frequência e respostas.
- `Bootstrap`: liga os serviços ao RemoteEvent `NationProtocol`; identidade sempre
  extraída de `OnServerEvent(player, ...)`, nunca recebida do payload.
- `NationReplica`: projeção local de snapshots/deltas com revisão monotônica.
- `NationClient`: seleção, confirmação, estado pendente e recuperação de conexão.
- `MapGrid`/`MapView`: retângulos separados por proprietário e redesenho por bloco.

`ChooseCapital(cellId, requestId)` não aceita nome, proprietário, cor, tropas,
dinheiro ou contagem. Célula deve ser terrestre e livre, e o jogador não pode ter
outra nação. A validação/reserva não faz yield; pedidos para a mesma célula são
resolvidos sequencialmente com um único vencedor. IDs NaN, fracionários, tabelas,
strings e células de água são rejeitados.

Cada jogador tem limite de 6 comandos em rajada, reposição de 2/segundo e snapshots
separados por pelo menos 2 segundos. Excedentes são descartados. O cliente recupera
estado se a resposta demora, mas o servidor continua sendo a única autoridade.
Snapshots são enviados após o cliente conectar seu listener; entrada tardia,
mensagens antigas e lacunas de revisão são tratados. Não existe polling do mapa
durante operação normal; tentativas de sincronização ocorrem apenas na recuperação.

## Partida e limites

O estado é por servidor e por sessão, sem persistência nesta fase. Ao sair, o jogador
tem sua nação removida e as células liberadas; todos recebem o delta. Ao voltar,
escolhe uma nova capital. Uma requisição repetida não troca nem duplica capital.
IDs zero/negativos de jogadores de teste do Studio são suportados.

Ainda não há expansão, geração de tropas/ouro, combate, bots ativos, construções ou
persistência. Nenhum módulo legado foi reativado. A futura transferência de células
deverá atualizar propriedade, conjunto de células, contagem e capital no servidor.

## Validação executada

`python3 tools/test_lua.py`:

- Sintaxe dos 12 módulos novos/atuais.
- 178.199 verificações geográficas anteriores.
- 25.941 verificações de nação, rede, réplica e reconstrução de cores.
- 15 cenários/assertivas do fluxo cliente-servidor usando o controller, o gateway
  e o serviço reais com transporte/temporizadores simulados.

Inclui ocupação simultânea, segunda capital, saída/reentrada, entrada tardia,
payload inválido, frequência excessiva, snapshots independentes, mensagens antigas,
recuperação de revisão, timeout e bloqueio de confirmação antes de sincronizar.
Os testes não executam o motor gráfico do Roblox.

Pendências de teste no Studio/dispositivos:

- Abrir 2 jogadores: disputar a mesma célula, ocupar células diferentes e observar cores.
- Entrar com outro jogador depois das fundações; conferir capitais existentes.
- Sair com um jogador; verificar remoção do marcador e liberação da célula.
- Testar toque, pinça e rotação do aparelho; confirmar que arraste não funda capital.
- Conferir mapa com gráficos mínimos/máximos no iPhone/iPad.

## Publicação preservada

`default.project.json` não precisou mudar: as pastas já estão conectadas ao Rojo.
Nenhum workflow, secret, ID, autenticação ou configuração de publicação foi alterado.
O blob protegido de `publish-roblox.yml` continua
`49424381fa2dee049925d5229511c27e031158b5`.
O workflow legado `publish-worldwar.yml` também permanece intacto e não é acionado
pelos arquivos desta etapa. Build/publicação devem ser verificados no fluxo original.

Referências da integração:

- https://create.roblox.com/docs/scripting/events/remote
- https://create.roblox.com/docs/scripting/security/client-server-boundary

Próxima etapa: expansão adjacente e economia em ticks no servidor.
