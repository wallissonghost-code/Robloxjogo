# Etapa 1 — base do mapa (0.1.0-map-foundation)

Registro histórico da etapa 1. Estado atual: [Etapa 3 — expansão e economia](EXPANSION_ECONOMY.md).

## Estado encontrado

Base: `e260072807766c38debd09753db510f4351e7409` (`main`).
`default.project.json` carregava somente uma Baseplate. Os quatro módulos antigos
em `src/server` não tinham bootstrap, cliente ou configuração carregados pelo Rojo.
Não havia AGENTS.md na árvore do repositório.

O workflow protegido `.github/workflows/publish-roblox.yml` continua byte a byte
igual, com blob Git `49424381fa2dee049925d5229511c27e031158b5`.
Mantidos projeto, Rojo, autenticação, IDs, secrets e mecanismo de publicação.

Foi encontrado também `.github/workflows/publish-worldwar.yml`, já existente,
referenciando `worldwar.project.json` e `game/**`, ausentes. Ele foi preservado,
sem acionamento manual. Os arquivos alterados nesta etapa não correspondem aos
filtros de push desse workflow. Não foi criada outra infraestrutura.

## Implementado

- Configuração pública e versionada em `src/shared/Config.lua`.
- Contornos geográficos simplificados, sem fronteiras políticas, em WorldDefinition.
- Grade determinística 240 × 120: 28.800 posições, 8.633 células terrestres.
- IDs numéricos, costa, vizinhos terrestres cardinais e 120 blocos de até 16 × 16.
- MapService como entrada geográfica do servidor; nenhuma mutação remota disponível.
- Bootstrap cria o mapa no servidor e replica somente metadados de prontidão/versão.
- `default.project.json` conecta shared, server e client; Baseplate preservada.
- Cliente gera a mesma geografia estática. Ela não concede propriedade ou recursos.
- Prévia ScreenGui com 523 retângulos agrupados, nenhum Part/Billboard por célula.
- Arraste, pinça, roda do mouse, +/−, reenquadramento e inspeção de célula.
- Resize/orientação reenquadra e limita deslocamento; o mapa não pode girar.

Os módulos antigos BotService, Remotes, TerritoryService e TroopService permanecem
intactos. São ModuleScripts e não são requisitados pelo bootstrap novo.

## Limites desta entrega

É a etapa de fundação e prévia, **não a V1 jogável completa**. Ainda não há seleção
de capital, nações, propriedade, expansão, tropas, economia, combate ou bots ativos.
Os percentuais estão definidos na configuração, mas não comandam ataques ainda.
O personagem não é carregado automaticamente no modo mapa.

O mundo é aproximado: não é um atlas, omite Antártida, estreitos e ilhas menores.
O corte longitudinal não conecta automaticamente as bordas leste/oeste.
Ataques marítimos continuam fora do escopo.

## Validação

Execute na raiz:

```sh
python3 tools/test_lua.py
# Alternativa, se houver o executável Lua 5.4:
lua tests/map_spec.lua
```

O runner Python usa a biblioteca Lua 5.4 do sistema. Os módulos novos usam sintaxe
comum a Lua/Luau. Ele verifica sintaxe, entradas inválidas, ida/volta ID/coordenadas,
costas, simetria de vizinhos, pontos geográficos, determinismo e reconstrução exata
dos retângulos sem pintar água ou omitir terra. Não simula APIs do Roblox.

Resultado local: 178.199 verificações passaram. A silhueta foi inspecionada a partir
da grade real. A compilação Rojo e publicação devem ser confirmadas no workflow
original após o push. Sucesso do build não substitui teste em dispositivo.

Teste pendente em Studio/Roblox, celular e tablet:

1. Conferir versão e 8.633 células no cabeçalho.
2. Alternar gráficos mínimo/máximo com todo o mundo visível.
3. Testar arraste, pinça, zoom máximo, +/− e Ver mundo.
4. Girar o aparelho entre retrato/paisagem e verificar controles e limites do mapa.
5. Tocar terra, costa e oceano; conferir a célula indicada.
6. Confirmar ausência de personagem/controles de caminhada e erros no console.

ScreenGui foi escolhido porque a interface é exibida na tela, fora da renderização
de peças 3D distantes. A estabilidade visual e FPS ainda precisam de medição no
Roblox real, especialmente no iPhone/iPad. Referências consultadas:

- https://create.roblox.com/docs/ui
- https://create.roblox.com/docs/reference/engine/classes/GuiBase2d
- https://create.roblox.com/docs/reference/engine/classes/UserInputService

## Próxima etapa

NationService deve manter nações, capital, contagem e propriedade exclusivamente no
servidor. O gateway deve validar jogador, ID, estado e frequência de cada comando.
Alterações devem gerar deltas por bloco; não enviar/reconstruir o mundo inteiro.
TerritoryService usará a vizinhança densa do MapService. Economia, combate e decisões
de bots serão adicionados em etapas próprias, sem reativar os loops legados.
