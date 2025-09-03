# frozen_string_literal: true

module Imessage
  module Db
    class Engine < ::Rails::Engine
      isolate_namespace Imessage::Db

      config.generators do |g|
        g.test_framework :rspec
        g.fixture_replacement :factory_bot, dir: "spec/factories"
      end

      # Autoload models from the gem
      config.autoload_paths << File.expand_path("../models", __dir__)
    end
  end
end
