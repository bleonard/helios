require 'rack'

module Helios
  class Application
    def initialize(app = nil, options = {}, &block)
      @app = Rack::Builder.new do
        run Rack::Cascade.new([app, Helios::Backend.new(&block)].compact)
      end
    end

    def call(env)
      @app.call(env)
    end
  end
end

require 'helios/backend'
require 'helios/version'
