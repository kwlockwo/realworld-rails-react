#!/usr/bin/env bash
# exit on error
set -o errexit

# npm install
# npm run build
# npm run deploy

# the current version of Nokogiri ships with incompatible libs
bundle config --local build.nokogiri --use-system-libraries

bundle install
bundle exec rake assets:precompile
bundle exec rake assets:clean

# move to pre-deploy command if paid service
# bundle exec rake db:migrate 
