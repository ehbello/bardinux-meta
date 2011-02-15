#!/usr/bin/bash

TEMPLATE=page.tpl

echo '========================================================';
echo 'Generador de la web estatica de presentacion de Bardinux';
echo '========================================================';
echo ;
echo 'Introduce los siguientes parametros para rellenar la plantilla';
echo ;
echo ;
echo 'URL de la imagen de Bardinux';
read arg;
awk -v var=$arg '{ gsub(/<!--dibujo-->/,var,$0); print }' $TEMPLATE
echo 'Descripcion principal';
read arg;
awk -v var=$arg '{ gsub(/<!--descripcion-->/,var,$0); print }' $TEMPLATE
echo 'Tipo de aplicaciones 1';
read arg;
awk -v var=$arg '{ gsub(/<!--asunto1-->/,var,$0); print }' $TEMPLATE
echo 'Texto introduccion 1';
read arg;
awk -v var=$arg '{ gsub(/<!--asunto1-text-->/,var,$0); print }' $TEMPLATE
echo 'Imagen applicaciones 1';
read arg;
awk -v var=$arg '{ gsub(/<!--asunto1-img-->/,var,$0); print }' $TEMPLATE
echo 'Tipo de aplicaciones 2';
read arg;
awk -v var=$arg '{ gsub(/<!--asunto2-->/,var,$0); print }' $TEMPLATE
echo 'Texto introduccion 2';
read arg;
awk -v var=$arg '{ gsub(/<!--asunto2-text-->/,var,$0); print }' $TEMPLATE
echo 'Imagen applicaciones 2';
read arg;
awk -v var=$arg '{ gsub(/<!--asunto2-img-->/,var,$0); print }' $TEMPLATE

echo "enter id : a b c "
read -a array 
arr=${array[@]}
awk -v arr=$arr '{ 
  n=split($0,arr)
  if (NR==39) {	print arr[1]  }
  else if ( NR==40 ) { print arr[2] }
  else if ( NR==41 ) { print arr[3] }
  else if ( NR==42 ) { print arr[4] }
  .... #and so on
  { print }
}' "file"
