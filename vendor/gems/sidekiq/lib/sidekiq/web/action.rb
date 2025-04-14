# frozen_string_literal: true

module Sidekiq
  class WebAction
    RACK_SESSION = "rack.session"

    attr_accessor :env, :block, :type

    def settings
      Web.settings
    end

    def request
      @request ||= ::Rack::Request.new(env)
    end

    def halt(res)
      throw :halt, [res, {Rack::CONTENT_TYPE => "text/plain"}, [res.to_s]]
    end

    def redirect(location)
      throw :halt, [302, {Web::LOCATION => "#{request.base_url}#{location}"}, []]
    end

    def reload_page
      current_location = request.referer.gsub(request.base_url, "")
      redirect current_location
    end

    # deprecated, will warn in 8.0
    def params
      indifferent_hash = Hash.new { |hash, key| hash[key.to_s] if Symbol === key }

      indifferent_hash.merge! request.params
      route_params.each { |k, v| indifferent_hash[k.to_s] = v }

      indifferent_hash
    end

    # Use like `url_params("page")` within your action blocks
    def url_params(key)
      request.params[key]
    end

    # Use like `route_params(:name)` within your action blocks
    # key is required in 8.0, nil is only used for backwards compatibility
    def route_params(key = nil)
      if key
        env[WebRouter::ROUTE_PARAMS][key]
      else
        env[WebRouter::ROUTE_PARAMS]
      end
    end

    def session
      env[RACK_SESSION]
    end

    def erb(content, options = {})
      if content.is_a? Symbol
        unless respond_to?(:"_erb_#{content}")
          views = options[:views] || Web.settings.views
          filename = "#{views}/#{content}.erb"
          src = ERB.new(File.read(filename)).src

          # Need to use lineno less by 1 because erb generates a
          # comment before the source code.
          WebAction.class_eval <<-RUBY, filename, -1 # standard:disable Style/EvalWithLocation
            def _erb_#{content}
              #{src}
            end
          RUBY
        end
      end

      if @_erb
        _erb(content, options[:locals])
      else
        @_erb = true
        content = _erb(content, options[:locals])

        _render { content }
      end
    end

    def render(engine, content, options = {})
      raise "Only erb templates are supported" if engine != :erb

      erb(content, options)
    end

    def json(payload)
      [200, {Rack::CONTENT_TYPE => "application/json", Rack::CACHE_CONTROL => "private, no-store"}, [Sidekiq.dump_json(payload)]]
    end

    def initialize(env, block)
      @_erb = false
      @env = env
      @block = block
      @files ||= {}
    end

    private

    def _erb(file, locals)
      locals&.each { |k, v| define_singleton_method(k) { v } unless singleton_methods.include? k }

      if file.is_a?(String)
        ERB.new(file).result(binding)
      else
        send(:"_erb_#{file}")
      end
    end
  end
end
