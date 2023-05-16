# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'safe_session_store_patch', feature_category: :shared do
  shared_examples 'safe session store' do
    it 'allows storing a String' do
      session[:good_data] = 'hello world'

      expect(session[:good_data]).to eq('hello world')
    end

    it 'raises error when session attempts to store an unsafe object' do
      expect { session[:test] = Struct.new(:test) }
        .to raise_error(/Serializing novel Ruby objects can cause uninitialized constants in mixed deployments/)
    end

    it 'allows instance double of OneLogin::RubySaml::Response' do
      response_double = instance_double(OneLogin::RubySaml::Response)

      session[:response_double] = response_double

      expect(session[:response_double]).to eq(response_double)
    end

    it 'raises an error for instance double of REXML::Document' do
      response_double = instance_double(REXML::Document)

      expect { session[:response_double] = response_double }
        .to raise_error(/Serializing novel Ruby objects can cause uninitialized constants in mixed deployments/)
    end
  end

  context 'with ActionController::TestSession' do
    let(:session) { ActionController::TestSession.new }

    it_behaves_like 'safe session store'
  end

  context 'with ActionDispatch::Request::Session' do
    let(:dummy_store) do
      Class.new do
        def load_session(_env)
          [1, {}]
        end

        def session_exists?(_env)
          true
        end

        def delete_session(_env, _id, _options)
          123
        end
      end.new
    end

    let(:request) { ActionDispatch::Request.new({}) }
    let(:session) { ActionDispatch::Request::Session.create(dummy_store, request, {}) }

    it_behaves_like 'safe session store'
  end
end
