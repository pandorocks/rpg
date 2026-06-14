# frozen_string_literal: true

require "spec_helper"

require "rpg"
require "charming/test_helper"

# The local Charming checkout has uncommitted controller changes that reference
# Charming::Controller::Image without defining it. Provide a minimal test stub
# so controller specs can render; remove this once Charming supplies Image.
unless defined?(Charming::Controller::Image)
  module Charming
    class Controller
      class Image
        def self.collecting
          body = yield
          new(body, [])
        end

        attr_reader :body, :graphics

        def initialize(body, graphics)
          @body = body
          @graphics = graphics
        end
      end
    end
  end
end

RSpec.configure do |config|
  config.include Charming::TestHelper
  config.disable_monkey_patching!
  config.warnings = true
end
