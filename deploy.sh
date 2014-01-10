set -e
bundle exec jekyll build
git checkout -B master
rm -rf _src
mv public/* .
git add -A
git commit -m "Generated static HTML on $(date)" -a
git push origin master -f
git checkout source
