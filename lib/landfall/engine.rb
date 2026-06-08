# frozen_string_literal: true

module ::Landfall
  class Engine < ::Rails::Engine
    engine_name PLUGIN_NAME
    isolate_namespace Landfall
  end
end
