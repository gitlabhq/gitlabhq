# frozen_string_literal: true

require 'spec_helper'

require 'raven/transports/dummy'

RSpec.describe Gitlab::ErrorTracking do
  let(:exception) { RuntimeError.new('boom') }
  let(:issue_url) { 'http://gitlab.com/gitlab-org/gitlab-foss/issues/1' }

  let(:expected_payload_includes) do
    [
      { 'exception.class' => 'RuntimeError' },
      { 'exception.message' => 'boom' },
      { 'tags.correlation_id' => 'cid' },
      { 'extra.some_other_info' => 'info' },
      { 'extra.issue_url' => 'http://gitlab.com/gitlab-org/gitlab-foss/issues/1' }
    ]
  end

  let(:sentry_event) { Gitlab::Json.parse(Raven.client.transport.events.last[1]) }

  before do
    stub_sentry_settings

    allow(described_class).to receive(:sentry_dsn).and_return(Gitlab.config.sentry.dsn)
    allow(Labkit::Correlation::CorrelationId).to receive(:current_id).and_return('cid')

    described_class.configure do |config|
      config.encoding = 'json'
    end
  end

  describe '.configure' do
    context 'default tags from GITLAB_SENTRY_EXTRA_TAGS' do
      context 'when the value is a JSON hash' do
        it 'includes those tags in all events' do
          stub_env('GITLAB_SENTRY_EXTRA_TAGS', { foo: 'bar', baz: 'quux' }.to_json)

          described_class.configure do |config|
            config.encoding = 'json'
          end

          described_class.track_exception(StandardError.new)

          expect(sentry_event['tags'].except('correlation_id', 'locale', 'program'))
            .to eq('foo' => 'bar', 'baz' => 'quux')
        end
      end

      context 'when the value is not set' do
        before do
          stub_env('GITLAB_SENTRY_EXTRA_TAGS', nil)
        end

        it 'does not log an error' do
          expect(Gitlab::AppLogger).not_to receive(:debug)

          described_class.configure do |config|
            config.encoding = 'json'
          end
        end

        it 'does not send any extra tags' do
          described_class.configure do |config|
            config.encoding = 'json'
          end

          described_class.track_exception(StandardError.new)

          expect(sentry_event['tags'].keys).to contain_exactly('correlation_id', 'locale', 'program')
        end
      end

      context 'when the value is not a JSON hash' do
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

          it 'does not include any extra tags' do
            described_class.configure do |config|
              config.encoding = 'json'
            end

            described_class.track_exception(StandardError.new)

            expect(sentry_event['tags'].except('correlation_id', 'locale', 'program'))
              .to be_empty
          end

          it 'logs the error class' do
            expect(Gitlab::AppLogger).to receive(:debug).with(a_string_matching(error))

            described_class.configure do |config|
              config.encoding = 'json'
            end
          end
        end
      end
    end
  end

  describe '.with_context' do
    it 'adds the expected tags' do
      described_class.with_context {}

      expect(Raven.tags_context[:locale].to_s).to eq(I18n.locale.to_s)
      expect(Raven.tags_context[Labkit::Correlation::CorrelationId::LOG_KEY.to_sym].to_s)
        .to eq('cid')
    end
  end

  describe '.track_and_raise_for_dev_exception' do
    context 'when exceptions for dev should be raised' do
      before do
        expect(described_class).to receive(:should_raise_for_dev?).and_return(true)
      end

      it 'raises the exception' do
        expect(Raven).to receive(:capture_exception)

        expect { described_class.track_and_raise_for_dev_exception(exception) }
          .to raise_error(RuntimeError)
      end
    end

    context 'when exceptions for dev should not be raised' do
      before do
        expect(described_class).to receive(:should_raise_for_dev?).and_return(false)
      end

      it 'logs the exception with all attributes passed' do
        expected_extras = {
          some_other_info: 'info',
          issue_url: 'http://gitlab.com/gitlab-org/gitlab-foss/issues/1'
        }

        expected_tags = {
          correlation_id: 'cid'
        }

        expect(Raven).to receive(:capture_exception)
                           .with(exception,
                            tags: a_hash_including(expected_tags),
                            extra: a_hash_including(expected_extras))

        described_class.track_and_raise_for_dev_exception(
          exception,
          issue_url: issue_url,
          some_other_info: 'info'
        )
      end

      it 'calls Gitlab::ErrorTracking::Logger.error with formatted payload' do
        expect(Gitlab::ErrorTracking::Logger).to receive(:error)
          .with(a_hash_including(*expected_payload_includes))

        described_class.track_and_raise_for_dev_exception(
          exception,
          issue_url: issue_url,
          some_other_info: 'info'
        )
      end
    end
  end

  describe '.track_and_raise_exception' do
    it 'always raises the exception' do
      expect(Raven).to receive(:capture_exception)

      expect { described_class.track_and_raise_exception(exception) }
        .to raise_error(RuntimeError)
    end

    it 'calls Gitlab::ErrorTracking::Logger.error with formatted payload' do
      expect(Gitlab::ErrorTracking::Logger).to receive(:error)
        .with(a_hash_including(*expected_payload_includes))

      expect do
        described_class.track_and_raise_exception(
          exception,
          issue_url: issue_url,
          some_other_info: 'info'
        )
      end.to raise_error(RuntimeError)
    end
  end

  describe '.track_exception' do
    let(:extra) { { issue_url: issue_url, some_other_info: 'info' } }

    subject(:track_exception) { described_class.track_exception(exception, extra) }

    before do
      allow(Raven).to receive(:capture_exception).and_call_original
      allow(Gitlab::ErrorTracking::Logger).to receive(:error)
    end

    it 'calls Raven.capture_exception' do
      track_exception

      expect(Raven).to have_received(:capture_exception)
                   .with(exception,
                         tags: a_hash_including(correlation_id: 'cid'),
                         extra: a_hash_including(some_other_info: 'info', issue_url: issue_url))
    end

    it 'calls Gitlab::ErrorTracking::Logger.error with formatted payload' do
      track_exception

      expect(Gitlab::ErrorTracking::Logger).to have_received(:error)
                                           .with(a_hash_including(*expected_payload_includes))
    end

    context 'with filterable parameters' do
      let(:extra) { { test: 1, my_token: 'test' } }

      it 'filters parameters' do
        track_exception

        expect(Gitlab::ErrorTracking::Logger).to have_received(:error)
                                             .with(hash_including({ 'extra.test' => 1, 'extra.my_token' => '[FILTERED]' }))
      end
    end

    context 'the exception implements :sentry_extra_data' do
      let(:extra_info) { { event: 'explosion', size: :massive } }
      let(:exception) { double(message: 'bang!', sentry_extra_data: extra_info, backtrace: caller) }

      it 'includes the extra data from the exception in the tracking information' do
        track_exception

        expect(Raven).to have_received(:capture_exception)
                     .with(exception, a_hash_including(extra: a_hash_including(extra_info)))
      end
    end

    context 'the exception implements :sentry_extra_data, which returns nil' do
      let(:exception) { double(message: 'bang!', sentry_extra_data: nil, backtrace: caller) }
      let(:extra) { { issue_url: issue_url } }

      it 'just includes the other extra info' do
        track_exception

        expect(Raven).to have_received(:capture_exception)
                     .with(exception, a_hash_including(extra: a_hash_including(extra)))
      end
    end

    context 'with sidekiq args' do
      context 'when the args does not have anything sensitive' do
        let(:extra) { { sidekiq: { 'class' => 'PostReceive', 'args' => [1, { 'id' => 2, 'name' => 'hello' }, 'some-value', 'another-value'] } } }

        it 'ensures extra.sidekiq.args is a string' do
          track_exception

          expect(Gitlab::ErrorTracking::Logger).to have_received(:error).with(
            hash_including({ 'extra.sidekiq' => { 'class' => 'PostReceive', 'args' => ['1', '{"id"=>2, "name"=>"hello"}', 'some-value', 'another-value'] } }))
        end
      end

      context 'when the args has sensitive information' do
        let(:extra) { { sidekiq: { 'class' => 'UnknownWorker', 'args' => ['sensitive string', 1, 2] } } }

        it 'filters sensitive arguments before sending' do
          track_exception

          expect(sentry_event.dig('extra', 'sidekiq', 'args')).to eq(['[FILTERED]', 1, 2])
          expect(Gitlab::ErrorTracking::Logger).to have_received(:error).with(
            hash_including('extra.sidekiq' => { 'class' => 'UnknownWorker', 'args' => ['[FILTERED]', '1', '2'] }))
        end
      end
    end

    context 'when the error is kind of an `ActiveRecord::StatementInvalid`' do
      let(:exception) { ActiveRecord::StatementInvalid.new(sql: 'SELECT "users".* FROM "users" WHERE "users"."id" = 1 AND "users"."foo" = $1') }

      it 'injects the normalized sql query into extra' do
        track_exception

        expect(Raven).to have_received(:capture_exception)
          .with(exception, a_hash_including(extra: a_hash_including(sql: 'SELECT "users".* FROM "users" WHERE "users"."id" = $2 AND "users"."foo" = $1')))
      end
    end
  end
end
