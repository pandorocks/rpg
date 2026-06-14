# frozen_string_literal: true

require_relative "lib/rpg/version"

Gem::Specification.new do |spec|
  spec.name = "rpg"
  spec.version = Rpg::VERSION
  spec.summary = "A terminal roguelike built with Charming."
  spec.authors = ["pando"]
  spec.email = ["pando@example.com"]
  spec.files = Dir.glob("{app,config,exe,lib}/**/*") + %w[README.md]
  spec.bindir = "exe"
  spec.executables = ["rpg"]
  spec.require_paths = ["lib"]
  spec.required_ruby_version = ">= 4.0.0"
  spec.add_dependency "charming"
end
