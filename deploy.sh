set -e
git checkout master
bundle exec jekyll build -t
rm -rf src
git commit -m "Generated static HTML on $(date)" -a
git push origin master
git checkout source
