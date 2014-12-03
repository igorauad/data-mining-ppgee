Trabalho 3 - Deteccao de Imagens
=================

Esta pasta contem os scripts R (na pasta raiz) e MATLAB (na pasta "matlab"). O objetivo do trabalho é detectar bocas nas faces da base de dados. A metrica de avaliacao dos resultados deve ser o quão próxima a previsão é dos dados verdadeiros das 4 coordenads da boca (mouth_left_corner,  mouth_right_corner, mouth_center_top_lip, mouth_center_bottom_lip). O MATLAB trabalha detectando um retangulo no objeto alvo (a boca), portanto é possível avaliar quais as coordenadas deste retangulo detectado e comparar com as coordenadas verdadeiras.

Os algoritmos que devemos utilizar são:
* Correlaão
* Viola-Jones
* Gabor

O primero está implementado em R, pois aproveitei parte do que foi disponibilzado no tutorial que consta no Kaggle. O segundo é apropriado para ser avaliado no MATLAB ou OpenCV. Optei pelo MATLAB, pela familiaridade. Há detectores já treinados no MATLAB para componentes faciais, como boca, nariz e olhos. Devemos, no entanto, além de usar o detector do MATLAB, que é um objeto retornado por `vision.CascadeObjectDetector('Mouth')`, tentar treinar o nosso proprio detector utulizando a base fornecida. Para tanto, devemos aprender a usar a funcao `trainCascadeObjectDetector`. O terceiro algortimo, Gabor, ainda não sei onde podemos avalia-lo. É algo mais recente que o de Viola-Jones (que foi proposto em 2001), então deve ter menos codigo disponivel. Temos que ver se há no MATLAB algo. Métodos com redes neurais também são uma boa pedida.

Por último, deixei de fora do `Github` as bases de dados e as imagens, pois são arquivos grandes. As imagens estao compartilhadas em [https://www.dropbox.com/sh/b1zepolmoxc89qk/AAAKrcahWNKY2fVU9lcz7Xkza?dl=0](https://www.dropbox.com/sh/b1zepolmoxc89qk/AAAKrcahWNKY2fVU9lcz7Xkza?dl=0), e as bases [https://www.dropbox.com/sh/h5okzgfx9rl4fyo/AAB7i4l_1ATrGxslqttwettRa?dl=0](https://www.dropbox.com/sh/h5okzgfx9rl4fyo/AAB7i4l_1ATrGxslqttwettRa?dl=0), voces precisam baixa-las pra pasta `matlab/`.



