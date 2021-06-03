# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ErrorTracking::Processor::SanitizerProcessor do
  describe '.call' do
    let(:event) { Sentry.get_current_client.event_from_exception(exception) }
    let(:result_hash) { described_class.call(event).to_hash }

    before do
      data.each do |key, value|
        event.send("#{key}=", value)
      end
    end

    after do
      Sentry.get_current_scope.clear
    end

    context 'when event attributes contains sensitive information' do
      let(:exception) { RuntimeError.new }
      let(:data) do
        {
          contexts: {
            jwt: 'abcdef',
            controller: 'GraphController#execute'
          },
          tags: {
            variables: %w[some sensitive information'],
            deep_hash: {
              sharedSecret: 'secret123'
            }
          },
          user: {
            email: 'a@a.com',
            password: 'nobodyknows'
          },
          extra: {
            issue_url: 'http://gitlab.com/gitlab-org/gitlab-foss/-/issues/1',
            my_token: '[FILTERED]',
            another_token: '[FILTERED]'
          }
        }
      end

      it 'filters sensitive attributes' do
        expect_next_instance_of(ActiveSupport::ParameterFilter) do |instance|
          expect(instance).to receive(:filter).exactly(4).times.and_call_original
        end

        expect(result_hash).to include(
          contexts: {
            jwt: '[FILTERED]',
            controller: 'GraphController#execute'
          },
          tags: {
            variables: '[FILTERED]',
            deep_hash: {
              sharedSecret: '[FILTERED]'
            }
          },
          user: {
            email: 'a@a.com',
            password: '[FILTERED]'
          },
          extra: {
            issue_url: 'http://gitlab.com/gitlab-org/gitlab-foss/-/issues/1',
            my_token: '[FILTERED]',
            another_token: '[FILTERED]'
          }
        )
      end
    end

    context 'when request headers contains sensitive information' do
      let(:exception) { RuntimeError.new }
      let(:data) { {} }

      before do
        event.rack_env = {
          'HTTP_AUTHORIZATION' => 'Bearer 123456',
          'HTTP_PRIVATE_TOKEN' => 'abcdef',
          'HTTP_GITLAB_WORKHORSE_PROXY_START' => 123456
        }
      end

      it 'filters sensitive headers' do
        expect(result_hash[:request][:headers]).to include(
          'Authorization' => '[FILTERED]',
          'Private-Token' => '[FILTERED]',
          'Gitlab-Workhorse-Proxy-Start' => '123456'
        )
      end
    end
  end
end
