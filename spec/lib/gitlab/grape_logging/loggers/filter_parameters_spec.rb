# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GrapeLogging::Loggers::FilterParameters, feature_category: :api do
  subject { described_class.new }

  describe ".parameters" do
    let(:route) { instance_double('Grape::Router::Route', settings: settings) }
    let(:endpoint) { instance_double('Grape::Endpoint', route: route) }

    let(:env) do
      { 'rack.input' => '', Grape::Env::API_ENDPOINT => endpoint }
    end

    let(:mock_request) { ActionDispatch::Request.new(env) }

    before do
      mock_request.params['key'] = 'some key'
      mock_request.params['foo'] = 'wibble'
      mock_request.params['value'] = 'some value'
      mock_request.params['oof'] = 'wobble'
      mock_request.params['other'] = 'Unaffected'
    end

    context 'when the log_safety setting is provided' do
      let(:settings) { { log_safety: { safe: %w[foo bar key], unsafe: %w[oof rab value] } } }

      it 'includes safe parameters, and filters unsafe ones' do
        data = subject.parameters(mock_request, nil)

        expect(data).to eq(
          params: {
            'key' => 'some key',
            'foo' => 'wibble',
            'value' => '[FILTERED]',
            'oof' => '[FILTERED]',
            'other' => 'Unaffected'
          }
        )
      end
    end

    context 'when log_safety includes unsafe_nested' do
      before do
        mock_request.params['inputs'] = [
          { 'name' => 'secret_input', 'value' => 'top-secret' },
          { 'name' => 'other_input', 'value' => 'also-secret' }
        ]
      end

      let(:settings) { { log_safety: { unsafe_nested: [%w[inputs value]] } } }

      it 'redacts the nested value field within each array element' do
        data = subject.parameters(mock_request, nil)

        expect(data[:params]['inputs']).to eq([
          { 'name' => 'secret_input', 'value' => '[FILTERED]' },
          { 'name' => 'other_input', 'value' => '[FILTERED]' }
        ])
      end

      it 'does not affect other parameters', :aggregate_failures do
        data = subject.parameters(mock_request, nil)

        expect(data[:params]['other']).to eq('Unaffected')
        expect(data[:params]['foo']).to eq('wibble')
      end
    end

    context 'when the log_safety is not provided' do
      let(:settings) { {} }

      it 'behaves like the normal parameter filter' do
        data = subject.parameters(mock_request, nil)

        expect(data).to eq(
          params: {
            'key' => '[FILTERED]',
            'foo' => 'wibble',
            'value' => 'some value',
            'oof' => 'wobble',
            'other' => 'Unaffected'
          }
        )
      end
    end
  end
end
