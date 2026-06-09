# frozen_string_literal: true

# Rails-free spec helper for Landfall's pure-logic unit specs (Tier 1). These specs
# load only the file under test, so they run fast and are the subjects mutation-tested
# by mutant.
#
# Under Discourse's test suite the specs are loaded via rails_helper and RSpec is
# already configured, so we only apply our own configuration when running standalone
# (mutant / fast unit runs) to avoid clobbering the shared configuration.
unless defined?(Rails)
  RSpec.configure do |config|
    config.expect_with(:rspec) { |c| c.syntax = :expect }
    config.disable_monkey_patching!
    config.order = :random
  end
end
