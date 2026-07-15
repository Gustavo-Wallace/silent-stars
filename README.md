# Silent Stars

Protótipo experimental de exploração espacial feito em Godot 4, usando somente elementos nativos e desenho procedural.

Explore um mapa estelar silencioso, observe sistemas e considere o custo de se tornar visível no universo. Informações são úteis — mas nem todo conhecimento é silencioso.

## Controles

- Arraste com o botão direito ou botão do meio para mover a câmera.
- Use a roda do mouse para aproximar ou afastar.
- Clique em uma estrela para consultar sua telemetria.
- Use **Passive Observe** para revelar tipo, recursos estimados e atividade sem aumentar a assinatura cósmica.
- Use **Active Scan** para revelar leituras completas; cada escaneamento avança o ciclo e amplia sua assinatura cósmica.
- Use **Travel** em um sistema observado para deslocar a nave. Cada viagem custa 2 ENERGY, avança o ciclo e deixa uma assinatura proporcional à distância.

## Assinatura cósmica

A assinatura começa em **LOW**. Escaneamentos ativos acumulam sinal e avançam para **ELEVATED**, **LOUD** e **EXPOSED**. O contato permanece silencioso por enquanto, mas a interface já reage ao risco crescente.

## Recursos e extração

A civilização começa com **ENERGY 025**, **MATTER 010** e **DATA 000**. Sistemas observados permitem **Analyze Data**, que converte leituras em DATA com uma emissão pequena. Sistemas escaneados permitem **Begin Extraction**, que gera ENERGY e MATTER, mas emite um sinal maior.

Cada sistema suporta três extrações. Ao alcançar `3 / 3`, ele fica **Depleted**: sua luz enfraquece, cicatrizes orbitais permanecem visíveis e nenhuma extração adicional é possível.

Extração exige presença local: observe, escaneie, viaje até o sistema e então inicie a coleta.

## Nave e eventos de chegada

A nave ciano parte de Solace e deixa uma rota curta ao viajar. Chegadas geram um evento automático — de sinais fracos e destroços úteis a ecos de sensores e sombras que escutam. Os estados de contato atuais são **SILENT**, **UNEASY** e **WATCHED**.

## Pesquisa

Abra **Research** para converter ENERGY, MATTER e DATA em avanços permanentes. As categorias iniciais são **Silence**, **Exploration**, **Industry**, **Analysis** e **Survival**.

As oito tecnologias iniciais reduzem assinatura de scan/viagem, reduzem o custo de viagem, melhoram análise e extração, concedem DATA em observações passivas ou diminuem a incidência de eventos perigosos. Tecnologias com dependências permanecem bloqueadas até a pesquisa anterior ser concluída.

## Sondas remotas

O inventário começa com **PROBES 02**. Selecione um sistema observado fora da sua localização e use **Launch Probe**: custa 1 ENERGY e uma sonda, sem mover a nave principal. Sondas podem revelar leituras, arquivar DATA ou se perder; regiões ameaçadoras e uma assinatura alta aumentam o risco de rastreamento.

## Direção visual

Um observatório minimalista de fundo quase preto, estrelas suaves, rotas discretas e pulsos cianos que partem do sistema natal.

> Este é um protótipo experimental. Não utiliza imagens, áudio ou outros assets externos — apenas recursos nativos do Godot.
