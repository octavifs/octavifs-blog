set -e
hugo
mv public ../
git checkout master
cp -R ../public/* .
git add -A
git commit -m "$@"
git push
git checkout devel
rm -rf ../public
