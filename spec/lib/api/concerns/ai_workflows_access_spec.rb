# frozen_string_literal: true

require 'fast_spec_helper'
require 'grape'

RSpec.describe API::Concerns::AiWorkflowsAccess, feature_category: :duo_agent_platform do
  let(:dummy_class) do
    Class.new do
      include API::Concerns::AiWorkflowsAccess

      class << self
        attr_accessor :access_scopes

        def allow_access_with_scope(scope, options = {})
          (self.access_scopes ||= []) << { scope: scope, if: options[:if] }
        end
      end
    end
  end

  subject(:if_condition) { dummy_class.access_scopes.first[:if] }

  before do
    dummy_class.allow_ai_workflows_access
  end

  def request_for(verb)
    instance_double(
      Grape::Request,
      get?: verb == :get, head?: verb == :head, post?: verb == :post,
      put?: verb == :put, patch?: verb == :patch, delete?: verb == :delete
    )
  end

  it 'registers the ai_workflows scope' do
    expect(dummy_class.access_scopes.first[:scope]).to eq(:ai_workflows)
  end

  it 'allows read and write verbs' do
    %i[get head post put patch].each do |verb|
      expect(if_condition.call(request_for(verb))).to be(true)
    end
  end

  it 'rejects DELETE' do
    expect(if_condition.call(request_for(:delete))).to be(false)
  end
end
