set -e
hugo
mv public ../
git checkout master
cp -R ../public/* .
rm -rf ../public
git commit -m "$@"
git push
git checkout devel