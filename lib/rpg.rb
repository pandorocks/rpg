# frozen_string_literal: true

require "charming"
require "zeitwerk"

module Rpg
end

loader = Zeitwerk::Loader.new
loader.tag = "rpg"
loader.inflector.inflect("version" => "VERSION")
loader.push_dir(File.expand_path("rpg", __dir__), namespace: Rpg)
loader.push_dir(File.expand_path("../app/models", __dir__), namespace: Rpg)
loader.push_dir(File.expand_path("../app/state", __dir__), namespace: Rpg)
loader.push_dir(File.expand_path("../app/components", __dir__), namespace: Rpg)
loader.push_dir(File.expand_path("../app/views", __dir__), namespace: Rpg)
loader.push_dir(File.expand_path("../app/controllers", __dir__), namespace: Rpg)
loader.setup

require_relative "../config/routes"
