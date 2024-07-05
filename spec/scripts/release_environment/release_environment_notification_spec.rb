# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../scripts/release_environment/notification'
require 'webmock/rspec'

RSpec.describe ReleaseEnvironmentNotification, feature_category: :delivery do
  describe '#initialize' do
    context 'when NOT all environment variables are provided' do
      before do
        stub_env('ENVIRONMENT', nil)
      end

      it 'fail when initializing' do
        expect { described_class.new }.to raise_error(RuntimeError)
      end
    end

    context 'when an environment variable is set and empty' do
      before do
        stub_env('ENVIRONMENT', '')
      end

      it 'fail when initializing' do
        expect { described_class.new }.to raise_error(RuntimeError)
      end
    end

    context 'when all environment variables are provided' do
      before do
        stub_env('CI_PIPELINE_URL', '1')
        stub_env('ENVIRONMENT', 'my-env')
        stub_env('VERSIONS', '{"gitlab": "12.7.0"}')
        stub_env('OPS_RELEASE_TOOLS_PIPELINE_TOKEN', 'token')
        stub_env('RELEASE_ENVIRONMENT_NOTIFICATION_TYPE', 'qa')
      end

      it 'initializes' do
        expect { described_class.new }.not_to raise_error
      end
    end
  end

  describe '#execute' do
    context 'when all environment variables are provided' do
      before do
        stub_env('CI_PIPELINE_URL', '1')
        stub_env('ENVIRONMENT', 'my-env')
        stub_env('VERSIONS', '{"gitlab": "12.7.0"}')
        stub_env('OPS_RELEASE_TOOLS_PIPELINE_TOKEN', 'token')
        stub_env('RELEASE_ENVIRONMENT_NOTIFICATION_TYPE', 'qa')
      end

      context 'when the response is 2xx' do
        before do
          uri = URI.parse("#{ReleaseEnvironmentNotification::OPS_RELEASE_TOOLS_API_URL}/trigger/pipeline")
          stub_request(:any, uri).to_return(status: 200, body: 'Mocked response')
        end

        it 'triggers a notification' do
          notification = described_class.new

          expect(notification).to receive(:trigger_notification).and_call_original
          expect(notification.execute).to be_nil
        end
      end

      context 'when the response is not 2xx' do
        before do
          uri = URI.parse("#{ReleaseEnvironmentNotification::OPS_RELEASE_TOOLS_API_URL}/trigger/pipeline")
          stub_request(:any, uri).to_return(status: 404, body: 'Mocked response')
        end

        it 'raise an error' do
          notification = described_class.new
          expect(notification).to receive(:trigger_notification).and_call_original
          expect { notification.execute }.to raise_error(RuntimeError)
        end
      end
    end
  end
end
