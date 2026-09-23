# frozen_string_literal: true

require 'fast_spec_helper'
require 'grape'

RSpec.describe API::Concerns::McpAccess, feature_category: :mcp_server do
  let(:dummy_class) do
    Class.new do
      include API::Concerns::McpAccess

      class << self
        attr_accessor :access_scopes

        def allow_access_with_scope(scope, options = {})
          self.access_scopes ||= []
          self.access_scopes << { scope: scope, if: options[:if] }
        end
      end
    end
  end

  let(:mcp_route_endpoint) { endpoint_double(route_setting: { tool_name: :fork_repository }) }
  let(:empty_mcp_route_endpoint) { endpoint_double(route_setting: {}) }
  let(:plain_route_endpoint) { endpoint_double(route_setting: nil) }

  def endpoint_double(route_setting:)
    instance_double(Grape::Endpoint).tap do |endpoint|
      allow(endpoint).to receive(:route_setting).with(:mcp).and_return(route_setting)
    end
  end

  def request_double(verb, endpoint)
    instance_double(
      Grape::Request,
      get?: verb == :get, head?: verb == :head, post?: verb == :post, delete?: verb == :delete,
      put?: verb == :put, patch?: verb == :patch,
      env: { Grape::Env::API_ENDPOINT => endpoint }
    )
  end

  before do
    dummy_class.access_scopes = []
  end

  shared_examples 'an mcp access declaration' do |method_name, verb|
    subject(:if_condition) { dummy_class.access_scopes.first[:if] }

    before do
      dummy_class.public_send(method_name)
    end

    it 'adds the mcp scope' do
      expect(dummy_class.access_scopes.first[:scope]).to eq(:mcp)
    end

    it 'allows a request matching the verb on a route with an mcp route setting' do
      expect(if_condition.call(request_double(verb, mcp_route_endpoint))).to be true
    end

    # `Mcp::Tools::Manager` skips a blank route setting when it discovers tools, so an
    # empty setting is not a tool and must not authenticate either.
    it 'denies a request matching the verb on a route with an empty mcp route setting' do
      expect(if_condition.call(request_double(verb, empty_mcp_route_endpoint))).to be_falsey
    end

    it 'denies a request matching the verb on a route without an mcp route setting' do
      expect(if_condition.call(request_double(verb, plain_route_endpoint))).to be_falsey
    end

    it 'denies a request with a different verb, even on a route with an mcp route setting' do
      other_verb = %i[get post put delete].find { |v| v != verb }

      expect(if_condition.call(request_double(other_verb, mcp_route_endpoint))).to be false
    end
  end

  describe '.allow_mcp_access_create' do
    include_examples 'an mcp access declaration', :allow_mcp_access_create, :post
  end

  describe '.allow_mcp_access_read' do
    include_examples 'an mcp access declaration', :allow_mcp_access_read, :get
  end

  describe '.allow_mcp_access_update' do
    include_examples 'an mcp access declaration', :allow_mcp_access_update, :put
  end

  describe '.allow_mcp_access_delete' do
    include_examples 'an mcp access declaration', :allow_mcp_access_delete, :delete
  end
end
