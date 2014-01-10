set -e
bundle exec jekyll build
git checkout -B master
rm -rf src
mv public/* .
git add -A
git commit -m "Generated static HTML on $(date)"
git push origin master -f
git checkout source
