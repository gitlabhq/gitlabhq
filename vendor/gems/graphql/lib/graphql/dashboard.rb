# frozen_string_literal: true
require 'rails/engine'

module Graphql
  # `GraphQL::Dashboard` is a `Rails::Engine`-based dashboard for viewing metadata about your GraphQL schema.
  #
  # Pass the class name of your schema when mounting it.
  # @see GraphQL::Tracing::DetailedTrace DetailedTrace for viewing production traces in the Dashboard
  #
  # @example Mounting the Dashboard in your app
  #   mount GraphQL::Dashboard, at: "graphql_dashboard", schema: "MySchema"
  #
  # @example Authenticating the Dashboard with HTTP Basic Auth
  #   # config/initializers/graphql_dashboard.rb
  #   GraphQL::Dashboard.middleware.use(Rack::Auth::Basic) do |username, password|
  #     # Compare the provided username/password to an application setting:
  #     ActiveSupport::SecurityUtils.secure_compare(Rails.application.credentials.graphql_dashboard_username, username) &&
  #       ActiveSupport::SecurityUtils.secure_compare(Rails.application.credentials.graphql_dashboard_username, password)
  #   end
  #
  # @example Custom Rails authentication
  #   # config/initializers/graphql_dashboard.rb
  #   ActiveSupport.on_load(:graphql_dashboard_application_controller) do
  #     # context here is GraphQL::Dashboard::ApplicationController
  #
  #     before_action do
  #       raise ActionController::RoutingError.new('Not Found') unless current_user&.admin?
  #     end
  #
  #     def current_user
  #       # load current user
  #     end
  #   end
  #
  class Dashboard < Rails::Engine
    engine_name "graphql_dashboard"
    isolate_namespace(Graphql::Dashboard)
    routes.draw do
      root "landings#show"
      resources :statics, only: :show, constraints: { id: /[0-9A-Za-z\-.]+/ }
      delete "/traces/delete_all", to: "traces#delete_all", as: :traces_delete_all
      resources :traces, only: [:index, :show, :destroy]
    end

    class ApplicationController < ActionController::Base
      protect_from_forgery with: :exception
      prepend_view_path(File.join(__FILE__, "../dashboard/views"))

      content_security_policy do |policy|
        policy.default_src(:self) if policy.default_src(*policy.default_src).blank?
        policy.connect_src(:self) if policy.connect_src(*policy.connect_src).blank?
        policy.base_uri(:none) if policy.base_uri(*policy.base_uri).blank?
        policy.font_src(:self) if policy.font_src(*policy.font_src).blank?
        policy.img_src(:self, :data) if policy.img_src(*policy.img_src).blank?
        policy.object_src(:none) if policy.object_src(*policy.object_src).blank?
        policy.script_src(:self) if policy.script_src(*policy.script_src).blank?
        policy.style_src(:self) if policy.style_src(*policy.style_src).blank?
        policy.form_action(:self) if policy.form_action(*policy.form_action).blank?
        policy.frame_ancestors(:none) if policy.frame_ancestors(*policy.frame_ancestors).blank?
      end

      def schema_class
        @schema_class ||= begin
          schema_param = request.query_parameters["schema"] || params[:schema]
          case schema_param
          when Class
            schema_param
          when String
            schema_param.constantize
          else
            raise "Missing `params[:schema]`, please provide a class or string to `mount GraphQL::Dashboard, schema: ...`"
          end
        end
      end
      helper_method :schema_class
    end

    class LandingsController < ApplicationController
      def show
      end
    end

    class TracesController < ApplicationController
      def index
        @detailed_trace_installed = !!schema_class.detailed_trace
        if @detailed_trace_installed
          @last = params[:last]&.to_i || 50
          @before = params[:before]&.to_i
          @traces = schema_class.detailed_trace.traces(last: @last, before: @before)
        end
      end

      def show
        trace = schema_class.detailed_trace.find_trace(params[:id].to_i)
        send_data(trace.trace_data)
      end

      def destroy
        schema_class.detailed_trace.delete_trace(params[:id])
        head :no_content
      end

      def delete_all
        schema_class.detailed_trace.delete_all_traces
        head :no_content
      end
    end

    class StaticsController < ApplicationController
      skip_after_action :verify_same_origin_request
      # Use an explicit list of files to avoid any chance of reading other files from disk
      STATICS = {}

      [
        "icon.png",
        "header-icon.png",
        "dashboard.css",
        "dashboard.js",
        "bootstrap-5.3.3.min.css",
        "bootstrap-5.3.3.min.js",
      ].each do |static_file|
        STATICS[static_file] = File.expand_path("../dashboard/statics/#{static_file}", __FILE__)
      end

      def show
        expires_in 1.year, public: true
        if (filepath = STATICS[params[:id]])
          render file: filepath
        else
          head :not_found
        end
      end
    end
  end
end

# Rails expects the engine to be called `Graphql::Dashboard`,
# but `GraphQL::Dashboard` is consistent with this gem's naming.
# So define both constants to refer to the same class.
GraphQL::Dashboard = Graphql::Dashboard

ActiveSupport.run_load_hooks(:graphql_dashboard_application_controller, GraphQL::Dashboard::ApplicationController)
