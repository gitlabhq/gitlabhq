# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Tracing::RackMiddleware do
  using RSpec::Parameterized::TableSyntax

  describe '#call' do
    context 'for normal middleware flow' do
      let(:fake_app) { -> (env) { fake_app_response } }
      subject { described_class.new(fake_app) }
      let(:request) {  }

      context 'for 200 responses' do
        let(:fake_app_response) { [200, { 'Content-Type': 'text/plain' }, ['OK']] }

        it 'delegates correctly' do
          expect(subject.call(Rack::MockRequest.env_for("/"))).to eq(fake_app_response)
        end
      end

      context 'for 500 responses' do
        let(:fake_app_response) { [500, { 'Content-Type': 'text/plain' }, ['Error']] }

        it 'delegates correctly' do
          expect(subject.call(Rack::MockRequest.env_for("/"))).to eq(fake_app_response)
        end
      end
    end

    context 'when an application is raising an exception' do
      let(:custom_error) { Class.new(StandardError) }
      let(:fake_app) { ->(env) { raise custom_error } }

      subject { described_class.new(fake_app) }

      it 'delegates propagates exceptions correctly' do
        expect { subject.call(Rack::MockRequest.env_for("/")) }.to raise_error(custom_error)
      end
    end
  end

  describe '.build_sanitized_url_from_env' do
    def env_for_url(url)
      env = Rack::MockRequest.env_for(input_url)
      env['action_dispatch.parameter_filter'] = [/token/]

      env
    end

    where(:input_url, :output_url) do
      '/gitlab-org/gitlab-ce'                              | 'http://example.org/gitlab-org/gitlab-ce'
      '/gitlab-org/gitlab-ce?safe=1'                       | 'http://example.org/gitlab-org/gitlab-ce?safe=1'
      '/gitlab-org/gitlab-ce?private_token=secret'         | 'http://example.org/gitlab-org/gitlab-ce?private_token=%5BFILTERED%5D'
      '/gitlab-org/gitlab-ce?mixed=1&private_token=secret' | 'http://example.org/gitlab-org/gitlab-ce?mixed=1&private_token=%5BFILTERED%5D'
    end

    with_them do
      it { expect(described_class.build_sanitized_url_from_env(env_for_url(input_url))).to eq(output_url) }
    end
  end
end
