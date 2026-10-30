# Centro Militar — PNGs monocromáticos (Mundial War)

**Auditoria:** 16 construções reais e 8 armamentos reais. A arte `biohazard` é **reservada**; NÃO foi criada uma Bomba Biológica no jogo. A Bomba de Hidrogênio tem seu ícone exclusivo de fusão, a de Fragmentação usa a silhueta de bomba convencional.

## Arquivos

- `military-atlas.png`: PNG RGBA transparente, grade 5×5 de 64px (320×320). Inclui as 24 entradas jogáveis e a arte extra biohazard.
- `icons/*.png`: PNGs individuais para upload alternativo (verificação de conclusão abaixo).
- `vector_shapes.json`: formas vetoriais **originais e criadas para este jogo**; sem dependência de bibliotecas ou fontes de terceiros.
- `manifest.json`: IDs de tipos, nomes e offsets das imagens no atlas.
- `src/client/MilitaryIcons.lua`: associação centralizada de cada card a `ImageLabel`; tint padrão #B8BFCC, selecionado dourado, bloqueado cinza-escuro.

## ID ainda pendente — como concluir a publicação

1. No **Roblox Creator Dashboard**, publique `assets/military/military-atlas.png` como **imagem** da experiência e aguarde aprovação/moderação. É um asset diferente do ID do lugar publicado.
2. Em `src/client/MilitaryIcons.lua`, substitua `MilitaryIcons.ATLAS_ASSET_ID = nil` pelo ID de **imagem** real e verificado (número).
3. Faça commit do módulo para usar a publicação GitHub→Roblox que já existe. O workflow atual publica apenas o *place*: NÃO faz upload dos PNGs.
4. Opcionalmente publique PNGs individualmente e preencha `MilitaryIcons.Items.<kind>.assetId` (um asset publicado por tipo). IDs individuais têm prioridade sobre o atlas.

**Nunca invente IDs.** Enquanto não estiverem publicados, cada card mostra a silhueta monocromática local, gerada do próprio desenho com poucos `Frame` 2D; o módulo já cria o `ImageLabel` que assumirá após o upload. Esse fallback é **explícito** e não usa emojis nem `EditableImage`, portanto funciona também em gráfico baixo.

## Integração visual e preservação

O módulo serve **somente aos cards do Centro Militar**. O mapa continua com seus próprios desenhos, modelos da Cidade e cores; `OverlayRenderer.lua` e `GameConfig.Buildings[*].icon` não são substituídos. Nenhuma regra, construção, valor, efeito, modo, workflow, segredo ou ID de publicação foi alterado.

## Validação

Os 24 nomes do catálogo, posições de atlas, leitura de imagens e fallback podem ser testados estaticamente. A aprovação das imagens no Roblox, o carregamento via ID remoto, FPS e o layout real no celular/desktop exigem testes na experiência publicada; não estão automaticamente validados pelo commit.

### Pendências de asset

**Atlas inteiro: ID de imagem pendente.** Todos os 25 PNGs individuais também estão sem ID. Arte biohazard é apenas reserva.
