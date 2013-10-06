require 'rack'

module Helios
  class Backend < Rack::Builder
    DEFAULT_PATHS = {
      data: '/'
    }

    require 'rails-database-url' if const_defined?(:Rails)

    def initialize(*args, &block)
      raise ArgumentError, "Missing block" unless block_given?
      super(&nil)

      @services = {}

      instance_eval(&block)
    end

    def call(env)
      return super(env) unless env["REQUEST_METHOD"] == "OPTIONS" and env["REQUEST_PATH"] == "/"

      links = []
      @services.each do |path, middleware|
        links << %{<#{path}>; rel="#{middleware}"}
      end

      [206, {"Link" => links.join("\n")}, []]
    end

    private

    def service(identifier, options = {}, &block)
      if identifier.to_s == "admin"
        middleware = Helios::Frontend
      elsif identifier.is_a?(Class)
        middleware = identifier
      else
        begin
          middleware = Helios::Backend.const_get(constantize(identifier))
        rescue NameError
          raise LoadError, "Could not find matching service for #{identifier.inspect} (Helios::Backend::#{constantize(identifier)}). You may need to install an additional gem (such as helios-#{identifier})."
        end
      end

      options[:root] = "/#{(options.delete(:root) || DEFAULT_PATHS[identifier] || identifier)}".squeeze("/")

      map options[:root] do
        instance_eval(&block) if block_given?
        run middleware.new(self, options)
      end

      @services[options[:root]] = middleware
    end

    def constantize(identifier)
      identifier.to_s.split(/([[:alpha:]]*)/).select{|c| /[[:alpha:]]/ === c}.map(&:capitalize).join("")
    end
  end
end

require 'helios/frontend'
require 'helios/backend/data'
require 'helios/backend/in-app-purchase'
require 'helios/backend/passbook'
require 'helios/backend/push-notification'
require 'helios/backend/newsstand'
