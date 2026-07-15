# Silent Stars — Roadmap

## Visão geral

Silent Stars é uma experiência de exploração espacial minimalista inspirada na teoria da Floresta Negra: explorar traz conhecimento, mas toda ação pode tornar uma civilização mais visível no escuro.

## Etapa 1 — Fundação

Esta etapa estabelece um mapa estelar procedural, navegação por câmera, sistemas selecionáveis e uma HUD de observatório. Tudo é produzido por nodes e desenho nativo do Godot, sem assets externos.

## Etapa 2 — Primeiro dilema interativo (implementada)

Sistemas agora podem ser observados passivamente ou escaneados ativamente. A observação revela informação parcial sem emitir sinal; o escaneamento revela telemetria completa, avança o ciclo e aumenta a assinatura cósmica. A HUD acompanha ciclo, risco de assinatura, painel de conhecimento progressivo e log narrativo.

## Etapa 3 — Recursos e extração (implementada)

A civilização agora acompanha energia, matéria e dados. Sistemas possuem perfis de recurso próprios, obtidos por análise passiva ou por extração ativa. Extrair gera recursos e cicatrizes orbitais, aumenta a assinatura cósmica e eventualmente esgota o sistema.

## Etapa 4 — Viagem e chegadas (implementada)

Uma nave visível agora viaja entre sistemas observados, consumindo energia e deixando uma assinatura baseada na distância. A extração exige presença local. Cada chegada dispara um evento atmosférico automático, apresentado em uma telemetria discreta e registrado no log.

## Etapa 5 — Tecnologias iniciais (implementada)

O observatório agora mantém uma lista de pesquisa nas categorias Silence, Exploration, Industry, Analysis e Survival. Oito tecnologias consomem energia, matéria e dados para alterar imediatamente assinatura de scan e viagem, custo de viagem, rendimento de análise/extração, observação passiva e risco de eventos.

## Etapa 6 — Sondas remotas (implementada)

Sondas partem da localização atual sem deslocar a nave principal. Elas consomem energia e uma unidade do inventário, viajam visualmente e retornam telemetria, dados ou sinais de risco. Ameaça, distância, assinatura e tecnologias de sobrevivência influenciam a chance de perda e rastreamento.

## Etapa 7 — Eventos com escolhas (implementada)

Eventos de chegada agora apresentam respostas alternativas com custos e consequências sobre recursos, assinatura cósmica e estado de contato. A estrutura de dados permite ampliar o catálogo para eventos de sonda, scan, assinatura alta e cadeias narrativas futuras.

## Próximos passos

1. Eventos com escolhas.
2. Infraestrutura orbital.
3. Ameaça invisível progressiva.
4. Árvore tecnológica visual.
5. Construção de sondas.
6. Save / load.
7. Condições de vitória / derrota.
