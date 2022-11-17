# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GrapeLogging::Loggers::FilterParameters do
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
