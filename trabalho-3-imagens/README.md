Trabalho 3 - Deteccao de Imagens
=================

Esta pasta contem os scripts R (na pasta raiz) e MATLAB (na pasta "`matlab/`") utilizados no trabalho.

### Objetivos do Trabalho
 Detectar bocas nas faces da base de dados.

### Métrica de Avaliacao

RMSE entre os valores detectados e os valores verdadeiros das 4 coordenads da boca (`mouth_left_corner`,  `mouth_right_corner`, `mouth_center_top_lip`,` mouth_center_bottom_lip`).

O MATLAB trabalha detectando um retangulo no objeto alvo (a boca), portanto é possível avaliar quais as coordenadas deste retangulo detectado e comparar com as coordenadas verdadeiras.

## Métodos utilizados:
* Correlacão
* Viola-Jones

O primero está implementado em R, pois parte do que foi disponibilzado no tutorial que consta no Kaggle foi aproveitado. O segundo é apropriado para ser avaliado no MATLAB ou OpenCV. Optamos pelo MATLAB. Há detectores já treinados no MATLAB para componentes faciais como boca, nariz e olhos. No entanto, além de usar o detector do MATLAB, que é um objeto retornado por uma funcao como `vision.CascadeObjectDetector('Mouth')`, treinamos o nosso proprio detector utulizando a base fornecida. Para tanto, utilizamos a funcao `trainCascadeObjectDetector`.

---

**Importante:**
As bases de dados e as imagens foram deixadas de fora do `Github`, pois são arquivos grandes. As imagens estao compartilhadas em [https://www.dropbox.com/sh/b1zepolmoxc89qk/AAAKrcahWNKY2fVU9lcz7Xkza?dl=0](https://www.dropbox.com/sh/b1zepolmoxc89qk/AAAKrcahWNKY2fVU9lcz7Xkza?dl=0), e as bases em [https://www.dropbox.com/sh/h5okzgfx9rl4fyo/AAB7i4l_1ATrGxslqttwettRa?dl=0](https://www.dropbox.com/sh/h5okzgfx9rl4fyo/AAB7i4l_1ATrGxslqttwettRa?dl=0). É necessário baixa-las pra pasta `matlab/` nos seus repositorios locais para o que os códigos possam ser executados.



