# frozen_string_literal: true

# Rails-free spec helper for Landfall's pure-logic unit specs (Tier 1).
# These specs load only the files under test, so they run fast and are the subjects
# mutation-tested by mutant. The Discourse-integration specs (Tier 2) use the host
# app's rails_helper instead.

RSpec.configure do |config|
  config.expect_with(:rspec) { |c| c.syntax = :expect }
  config.disable_monkey_patching!
  config.order = :random
end
