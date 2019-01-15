hugo
mv public ../
checkout master
cp -R ../public .
rm -rf ../public
git commit -m $1
git push
git checkout devel