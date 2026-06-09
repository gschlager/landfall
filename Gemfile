# frozen_string_literal: true

# Standalone dependencies for Landfall's Tier-1 pure-logic test & mutation suite.
# These run without booting Discourse. Runtime plugin gems are declared in plugin.rb;
# the Discourse-integration specs (Tier 2) run inside the host app via rails_helper.
source "https://rubygems.org"

gem "bcrypt"

group :test do
  gem "rspec"
  gem "simplecov", require: false
  gem "mutant", require: false
  gem "mutant-rspec", require: false
end

# Linting — also used by Discourse's reusable plugin CI (`bundle exec rubocop`/`stree`).
group :development, :test do
  gem "rubocop-discourse", require: false
  gem "syntax_tree", require: false
end
