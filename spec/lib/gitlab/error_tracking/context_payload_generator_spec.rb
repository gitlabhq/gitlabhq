# frozen_string_literal: true

require 'fast_spec_helper'
require 'rspec-parameterized'

RSpec.describe Gitlab::ErrorTracking::ContextPayloadGenerator do
  subject(:generator) { described_class.new }

  let(:extra) do
    {
      some_other_info: 'info',
      issue_url: 'http://gitlab.com/gitlab-org/gitlab-foss/-/issues/1'
    }
  end

  let(:exception) { StandardError.new("Dummy exception") }

  before do
    allow(Labkit::Correlation::CorrelationId).to receive(:current_id).and_return('cid')
    allow(I18n).to receive(:locale).and_return('en')
  end

  context 'user metadata' do
    let(:user) { create(:user) }

    it 'appends user metadata to the payload' do
      payload = {}

      Gitlab::ApplicationContext.with_context(user: user) do
        payload = generator.generate(exception, extra)
      end

      expect(payload[:user]).to eql(
        username: user.username
      )
    end
  end

  context 'tags metadata' do
    context 'when the GITLAB_SENTRY_EXTRA_TAGS env is not set' do
      before do
        stub_env('GITLAB_SENTRY_EXTRA_TAGS', nil)
      end

      it 'does not log into AppLogger' do
        expect(Gitlab::AppLogger).not_to receive(:debug)

        generator.generate(exception, extra)
      end

      it 'does not send any extra tags' do
        payload = {}

        Gitlab::ApplicationContext.with_context(feature_category: 'feature_a') do
          payload = generator.generate(exception, extra)
        end

        expect(payload[:tags]).to eql(
          correlation_id: 'cid',
          locale: 'en',
          program: 'test',
          feature_category: 'feature_a'
        )
      end
    end

    context 'when the GITLAB_SENTRY_EXTRA_TAGS env is a JSON hash' do
      it 'includes those tags in all events' do
        stub_env('GITLAB_SENTRY_EXTRA_TAGS', { foo: 'bar', baz: 'quux' }.to_json)
        payload = {}

        Gitlab::ApplicationContext.with_context(feature_category: 'feature_a') do
          payload = generator.generate(exception, extra)
        end

        expect(payload[:tags]).to eql(
          correlation_id: 'cid',
          locale: 'en',
          program: 'test',
          feature_category: 'feature_a',
          'foo' => 'bar',
          'baz' => 'quux'
        )
      end

      it 'does not log into AppLogger' do
        expect(Gitlab::AppLogger).not_to receive(:debug)

        generator.generate(exception, extra)
      end
    end

    context 'when the GITLAB_SENTRY_EXTRA_TAGS env is not a JSON hash' do
      using RSpec::Parameterized::TableSyntax

      where(:env_var, :error) do
        { foo: 'bar', baz: 'quux' }.inspect | 'JSON::ParserError'
        [].to_json | 'NoMethodError'
        [%w[foo bar]].to_json | 'NoMethodError'
        %w[foo bar].to_json | 'NoMethodError'
        '"string"' | 'NoMethodError'
      end

      with_them do
        before do
          stub_env('GITLAB_SENTRY_EXTRA_TAGS', env_var)
        end

        it 'logs into AppLogger' do
          expect(Gitlab::AppLogger).to receive(:debug).with(a_string_matching(error))

          generator.generate({})
        end

        it 'does not include any extra tags' do
          payload = {}

          Gitlab::ApplicationContext.with_context(feature_category: 'feature_a') do
            payload = generator.generate(exception, extra)
          end

          expect(payload[:tags]).to eql(
            correlation_id: 'cid',
            locale: 'en',
            program: 'test',
            feature_category: 'feature_a'
          )
        end
      end
    end
  end

  context 'extra metadata' do
    it 'appends extra metadata to the payload' do
      payload = generator.generate(exception, extra)

      expect(payload[:extra]).to eql(
        some_other_info: 'info',
        issue_url: 'http://gitlab.com/gitlab-org/gitlab-foss/-/issues/1'
      )
    end

    it 'appends exception embedded extra metadata to the payload' do
      allow(exception).to receive(:sentry_extra_data).and_return(
        some_other_info: 'another_info',
        mr_url: 'https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/1'
      )

      payload = generator.generate(exception, extra)

      expect(payload[:extra]).to eql(
        some_other_info: 'another_info',
        issue_url: 'http://gitlab.com/gitlab-org/gitlab-foss/-/issues/1',
        mr_url: 'https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/1'
      )
    end

    it 'filters sensitive extra info' do
      extra[:my_token] = '456'
      allow(exception).to receive(:sentry_extra_data).and_return(
        mr_url: 'https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/1',
        another_token: '1234'
      )

      payload = generator.generate(exception, extra)

      expect(payload[:extra]).to eql(
        some_other_info: 'info',
        issue_url: 'http://gitlab.com/gitlab-org/gitlab-foss/-/issues/1',
        mr_url: 'https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/1',
        my_token: '[FILTERED]',
        another_token: '[FILTERED]'
      )
    end
  end
end
