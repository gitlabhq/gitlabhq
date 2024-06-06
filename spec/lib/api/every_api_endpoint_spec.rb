# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Every API endpoint', feature_category: :scalability do
  context 'feature categories' do
    let_it_be(:feature_categories) do
      Gitlab::FeatureCategories.default.categories.map(&:to_sym).to_set
    end

    let_it_be(:api_endpoints) do
      Gitlab::RequestEndpoints.all_api_endpoints.map do |route|
        [route.app.options[:for], API::Base.path_for_app(route.app)]
      end
    end

    let_it_be(:routes_without_category) do
      api_endpoints.map do |(klass, path)|
        next if klass.try(:feature_category_for_action, path)

        "#{klass}##{path}"
      end.compact.uniq
    end

    it "has feature categories" do
      expect(routes_without_category).to be_empty, "#{routes_without_category} did not have a category"
    end

    it "recognizes the feature categories" do
      routes_unknown_category = api_endpoints.map do |(klass, path)|
        used_category = klass.try(:feature_category_for_action, path)
        next unless used_category
        next if used_category == :not_owned

        [klass, path, used_category] unless feature_categories.include?(used_category)
      end.compact

      message = -> do
        list = routes_unknown_category.map do |klass, path, category|
          "- #{klass} (#{path}): #{category}"
        end

        <<~MESSAGE
          Unknown categories found for:
          #{list.join("\n")}
        MESSAGE
      end

      expect(routes_unknown_category).to be_empty, message
    end

    # This is required for API::Base.path_for_app to work, as it picks
    # the first path
    it "has no routes with multiple paths" do
      routes_with_multiple_paths = API::API.routes.select { |route| route.app.options[:path].length != 1 }
      failure_routes = routes_with_multiple_paths.map { |route| "#{route.app.options[:for]}:[#{route.app.options[:path].join(', ')}]" }

      expect(routes_with_multiple_paths).to be_empty, "#{failure_routes} have multiple paths"
    end

    it "doesn't define or exclude categories on removed actions", :aggregate_failures do
      api_endpoints.group_by(&:first).each do |klass, paths|
        existing_paths = paths.map(&:last)
        used_paths = paths_defined_in_feature_category_config(klass)
        non_existing_used_paths = used_paths - existing_paths

        expect(non_existing_used_paths).to be_empty,
          "#{klass} used #{non_existing_used_paths} to define feature category, but the route does not exist"
      end
    end
  end

  def paths_defined_in_feature_category_config(klass)
    (klass.try(:class_attributes) || {}).fetch(:feature_category_config, {})
      .values
      .flatten
      .map(&:to_s)
  end
end
