# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable Rails/HttpPositionalArguments
RSpec.describe ::API::Base do
  let(:app_hello) do
    route = double(:route, request_method: 'GET', path: '/:version/test/hello')
    double(:endpoint, route: route, options: { for: api_handler, path: ["hello"] }, namespace: '/test')
  end

  let(:app_hi) do
    route = double(:route, request_method: 'GET', path: '/:version//test/hi')
    double(:endpoint, route: route, options: { for: api_handler, path: ["hi"] }, namespace: '/test')
  end

  describe 'declare feature categories at handler level for all routes' do
    let(:api_handler) do
      Class.new(described_class) do
        feature_category :foo
        urgency :medium

        namespace '/test' do
          get 'hello' do
          end
          post 'hi' do
          end
        end
      end
    end

    it 'sets feature category for a particular route', :aggregate_failures do
      expect(api_handler.feature_category_for_app(app_hello)).to eq(:foo)
      expect(api_handler.feature_category_for_app(app_hi)).to eq(:foo)
    end

    it 'sets request urgency for a particular route', :aggregate_failures do
      expect(api_handler.urgency_for_app(app_hello)).to be_request_urgency(:medium)
      expect(api_handler.urgency_for_app(app_hi)).to be_request_urgency(:medium)
    end
  end

  describe 'declare feature categories at route level' do
    let(:api_handler) do
      Class.new(described_class) do
        namespace '/test' do
          get 'hello', feature_category: :foo, urgency: :low do
          end
          post 'hi', feature_category: :bar, urgency: :medium do
          end
        end
      end
    end

    it 'sets feature category for a particular route', :aggregate_failures do
      expect(api_handler.feature_category_for_app(app_hello)).to eq(:foo)
      expect(api_handler.feature_category_for_app(app_hi)).to eq(:bar)
    end

    it 'sets request urgency for a particular route', :aggregate_failures do
      expect(api_handler.urgency_for_app(app_hello)).to be_request_urgency(:low)
      expect(api_handler.urgency_for_app(app_hi)).to be_request_urgency(:medium)
    end
  end

  describe 'declare feature categories at both handler level and route level' do
    let(:api_handler) do
      Class.new(described_class) do
        feature_category :foo, ['/test/hello']
        urgency :low, ['/test/hello']

        namespace '/test' do
          get 'hello' do
          end
          post 'hi', feature_category: :bar, urgency: :medium do
          end
        end
      end
    end

    it 'sets feature category for a particular route', :aggregate_failures do
      expect(api_handler.feature_category_for_app(app_hello)).to eq(:foo)
      expect(api_handler.feature_category_for_app(app_hi)).to eq(:bar)
    end

    it 'sets target duration for a particular route', :aggregate_failures do
      expect(api_handler.urgency_for_app(app_hello)).to be_request_urgency(:low)
      expect(api_handler.urgency_for_app(app_hi)).to be_request_urgency(:medium)
    end
  end
end
# rubocop:enable Rails/HttpPositionalArguments
