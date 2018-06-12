#! /bin/bash

check() {
if [ ! -s $1 ] ; then 
	echo "Missing $1"
	exit
fi
}

size=57.6
key=water.key
sed "s/AXIS/$size/" key.key > $key

# Make water box
rm -f water.xyz_2
echo 19 > water.edit
echo 3391 >> water.edit
echo $size $size $size >> water.edit
xyzedit water.xyz -k $key < water.edit
check water.xyz_2
# Renumber water box
rm -f water.xyz_3
echo 1 > water.edit
echo 0 >> water.edit
echo 16 >> water.edit
xyzedit water.xyz_2 -k $key < water.edit
check water.xyz_3
# Minimize with direct polarization
rm -f water.xyz_4
minimize water.xyz_3 -k $key 10
check water.xyz_4
# Better minimization with direct polarization
rm -f water.xyz_5
sed '/steepest-descent/d' $key > ${key}_direct0
minimize water.xyz_4 -k ${key}_direct0 0.01
check water.xyz_5
# Minimize with mutal polarization
rm -f water.xyz_6
sed 's/direct/mutual/' $key > ${key}_mutual0
sed -i '/steepest-descent/d' ${key}_mutual0
minimize water.xyz_5 -k ${key}_mutual0 0.01
check water.xyz_6
