# Silent Stars

Protótipo experimental de exploração espacial feito em Godot 4, usando somente elementos nativos e desenho procedural.

Explore um mapa estelar silencioso, observe sistemas e considere o custo de se tornar visível no universo. Informações são úteis — mas nem todo conhecimento é silencioso.

## Controles

- Arraste com o botão direito ou botão do meio para mover a câmera.
- Use a roda do mouse para aproximar ou afastar.
- Clique em uma estrela para consultar sua telemetria.
- Use **Passive Observe** para revelar tipo, recursos estimados e atividade sem aumentar a assinatura cósmica.
- Use **Active Scan** para revelar leituras completas; cada escaneamento avança o ciclo e amplia sua assinatura cósmica.

## Assinatura cósmica

A assinatura começa em **LOW**. Escaneamentos ativos acumulam sinal e avançam para **ELEVATED**, **LOUD** e **EXPOSED**. O contato permanece silencioso por enquanto, mas a interface já reage ao risco crescente.

## Recursos e extração

A civilização começa com **ENERGY 025**, **MATTER 010** e **DATA 000**. Sistemas observados permitem **Analyze Data**, que converte leituras em DATA com uma emissão pequena. Sistemas escaneados permitem **Begin Extraction**, que gera ENERGY e MATTER, mas emite um sinal maior.

Cada sistema suporta três extrações. Ao alcançar `3 / 3`, ele fica **Depleted**: sua luz enfraquece, cicatrizes orbitais permanecem visíveis e nenhuma extração adicional é possível.

## Direção visual

Um observatório minimalista de fundo quase preto, estrelas suaves, rotas discretas e pulsos cianos que partem do sistema natal.

> Este é um protótipo experimental. Não utiliza imagens, áudio ou outros assets externos — apenas recursos nativos do Godot.
