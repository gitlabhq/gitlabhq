# frozen_string_literal: true

require "erb"

require "sidekiq"
require "sidekiq/api"
require "sidekiq/paginator"
require "sidekiq/web/helpers"

require "sidekiq/web/router"
require "sidekiq/web/action"
require "sidekiq/web/application"
require "sidekiq/web/csrf_protection"

require "rack/content_length"
require "rack/builder"
require "rack/static"

module Sidekiq
  class Web
    ROOT = File.expand_path("#{File.dirname(__FILE__)}/../../web")
    VIEWS = "#{ROOT}/views"
    LOCALES = ["#{ROOT}/locales"]
    LAYOUT = "#{VIEWS}/layout.erb"
    ASSETS = "#{ROOT}/assets"

    DEFAULT_TABS = {
      "Dashboard" => "",
      "Busy" => "busy",
      "Queues" => "queues",
      "Retries" => "retries",
      "Scheduled" => "scheduled",
      "Dead" => "morgue",
      "Metrics" => "metrics"
    }

    if Gem::Version.new(Rack::RELEASE) < Gem::Version.new("3")
      CONTENT_LANGUAGE = "Content-Language"
      CONTENT_SECURITY_POLICY = "Content-Security-Policy"
      LOCATION = "Location"
      X_CASCADE = "X-Cascade"
    else
      CONTENT_LANGUAGE = "content-language"
      CONTENT_SECURITY_POLICY = "content-security-policy"
      LOCATION = "location"
      X_CASCADE = "x-cascade"
    end

    class << self
      def settings
        self
      end

      def default_tabs
        DEFAULT_TABS
      end

      def custom_tabs
        @custom_tabs ||= {}
      end
      alias_method :tabs, :custom_tabs

      def custom_job_info_rows
        @custom_job_info_rows ||= []
      end

      def locales
        @locales ||= LOCALES
      end

      def views
        @views ||= VIEWS
      end

      def enable(*opts)
        opts.each { |key| set(key, true) }
      end

      def disable(*opts)
        opts.each { |key| set(key, false) }
      end

      def middlewares
        @middlewares ||= []
      end

      def use(*args, &block)
        middlewares << [args, block]
      end

      def set(attribute, value)
        send(:"#{attribute}=", value)
      end

      attr_accessor :app_url, :redis_pool
      attr_writer :locales, :views
    end

    def self.inherited(child)
      child.app_url = app_url
      child.redis_pool = redis_pool
    end

    def settings
      self.class.settings
    end

    def middlewares
      @middlewares ||= self.class.middlewares
    end

    def use(*args, &block)
      middlewares << [args, block]
    end

    def call(env)
      app.call(env)
    end

    def self.call(env)
      @app ||= new
      @app.call(env)
    end

    def app
      @app ||= build
    end

    def enable(*opts)
      opts.each { |key| set(key, true) }
    end

    def disable(*opts)
      opts.each { |key| set(key, false) }
    end

    def set(attribute, value)
      send(:"#{attribute}=", value)
    end

    def self.register(extension)
      extension.registered(WebApplication)
    end

    private

    def build
      klass = self.class
      m = middlewares

      rules = []
      rules = [[:all, {Rack::CACHE_CONTROL => "private, max-age=86400"}]] unless ENV["SIDEKIQ_WEB_TESTING"]

      ::Rack::Builder.new do
        use Rack::Static, urls: ["/stylesheets", "/images", "/javascripts"],
          root: ASSETS,
          cascade: true,
          header_rules: rules
        m.each { |middleware, block| use(*middleware, &block) }
        use Sidekiq::Web::CsrfProtection unless $TESTING
        run WebApplication.new(klass)
      end
    end
  end

  Sidekiq::WebApplication.helpers WebHelpers
  Sidekiq::WebApplication.helpers Sidekiq::Paginator

  Sidekiq::WebAction.class_eval <<-RUBY, __FILE__, __LINE__ + 1
    def _render
      #{ERB.new(File.read(Web::LAYOUT)).src}
    end
  RUBY
end
