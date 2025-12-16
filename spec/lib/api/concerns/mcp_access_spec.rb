# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe API::Concerns::McpAccess, feature_category: :mcp_server do
  let(:dummy_class) do
    Class.new do
      include API::Concerns::McpAccess

      class << self
        attr_accessor :access_scopes

        def allow_access_with_scope(scope, _options = {})
          self.access_scopes ||= []
          self.access_scopes << scope
        end
      end
    end
  end

  before do
    dummy_class.access_scopes = []
  end

  describe '.allow_mcp_access_create' do
    it 'adds mcp scope' do
      dummy_class.allow_mcp_access_create

      expect(dummy_class.access_scopes).to include(:mcp)
    end
  end

  describe '.allow_mcp_access_read' do
    it 'adds mcp scope' do
      dummy_class.allow_mcp_access_read

      expect(dummy_class.access_scopes).to include(:mcp)
    end
  end
end
