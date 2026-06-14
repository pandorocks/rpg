# frozen_string_literal: true

require "spec_helper"

require "rpg"
require "charming/test_helper"

RSpec.configure do |config|
  config.include Charming::TestHelper
  config.disable_monkey_patching!
  config.warnings = true
end
