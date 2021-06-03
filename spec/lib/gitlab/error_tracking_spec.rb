# frozen_string_literal: true

require 'spec_helper'

require 'sentry/transport/dummy_transport'

RSpec.describe Gitlab::ErrorTracking do
  let(:exception) { RuntimeError.new('boom') }
  let(:issue_url) { 'http://gitlab.com/gitlab-org/gitlab-foss/issues/1' }
  let(:extra) { { issue_url: issue_url, some_other_info: 'info' } }

  let(:user) { create(:user) }

  let(:sentry_payload) do
    {
      tags: {
        program: 'test',
        locale: 'en',
        feature_category: 'feature_a',
        correlation_id: 'cid'
      },
      user: {
        username: user.username
      },
      extra: {
        some_other_info: 'info',
        issue_url: 'http://gitlab.com/gitlab-org/gitlab-foss/issues/1'
      }
    }
  end

  let(:logger_payload) do
    {
      'exception.class' => 'RuntimeError',
      'exception.message' => 'boom',
      'tags.program' => 'test',
      'tags.locale' => 'en',
      'tags.feature_category' => 'feature_a',
      'tags.correlation_id' => 'cid',
      'user.username' => user.username,
      'extra.some_other_info' => 'info',
      'extra.issue_url' => 'http://gitlab.com/gitlab-org/gitlab-foss/issues/1'
    }
  end

  let(:sentry_event) { Sentry.get_current_client.transport.events.last }

  before do
    stub_sentry_settings

    allow(described_class).to receive(:sentry_dsn).and_return(Gitlab.config.sentry.dsn)
    allow(Labkit::Correlation::CorrelationId).to receive(:current_id).and_return('cid')
    allow(I18n).to receive(:locale).and_return('en')

    described_class.configure do |config|
      config.transport.transport_class = Sentry::DummyTransport
    end
  end

  around do |example|
    Gitlab::ApplicationContext.with_context(user: user, feature_category: 'feature_a') do
      example.run
    end
  end

  after do
    ::Sentry.get_current_scope.clear
  end

  describe '.track_and_raise_for_dev_exception' do
    context 'when exceptions for dev should be raised' do
      before do
        expect(described_class).to receive(:should_raise_for_dev?).and_return(true)
      end

      it 'raises the exception' do
        expect(Sentry).to receive(:capture_exception).with(exception, sentry_payload)

        expect do
          described_class.track_and_raise_for_dev_exception(
            exception,
            issue_url: issue_url,
            some_other_info: 'info'
          )
        end.to raise_error(RuntimeError, /boom/)
      end
    end

    context 'when exceptions for dev should not be raised' do
      before do
        expect(described_class).to receive(:should_raise_for_dev?).and_return(false)
      end

      it 'logs the exception with all attributes passed' do
        expect(Sentry).to receive(:capture_exception).with(exception, sentry_payload)

        described_class.track_and_raise_for_dev_exception(
          exception,
          issue_url: issue_url,
          some_other_info: 'info'
        )
      end

      it 'calls Gitlab::ErrorTracking::Logger.error with formatted payload' do
        expect(Gitlab::ErrorTracking::Logger).to receive(:error).with(logger_payload)

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
      expect(Sentry).to receive(:capture_exception).with(exception, sentry_payload)

      expect do
        described_class.track_and_raise_for_dev_exception(
          exception,
          issue_url: issue_url,
          some_other_info: 'info'
        )
      end.to raise_error(RuntimeError, /boom/)
    end

    it 'calls Gitlab::ErrorTracking::Logger.error with formatted payload' do
      expect(Gitlab::ErrorTracking::Logger).to receive(:error).with(logger_payload)

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
    subject(:track_exception) { described_class.track_exception(exception, extra) }

    before do
      allow(Sentry).to receive(:capture_exception).and_call_original
      allow(Gitlab::ErrorTracking::Logger).to receive(:error)
    end

    it 'calls Sentry.capture_exception' do
      track_exception

      expect(Sentry).to have_received(:capture_exception).with(
        exception,
        sentry_payload
      )
    end

    it 'calls Gitlab::ErrorTracking::Logger.error with formatted payload' do
      track_exception

      expect(Gitlab::ErrorTracking::Logger).to have_received(:error).with(logger_payload)
    end

    context 'with filterable parameters' do
      let(:extra) { { test: 1, my_token: 'test' } }

      it 'filters parameters' do
        track_exception

        expect(Gitlab::ErrorTracking::Logger).to have_received(:error).with(
          hash_including({ 'extra.test' => 1, 'extra.my_token' => '[FILTERED]' })
        )
      end
    end

    context 'the exception implements :sentry_extra_data' do
      let(:extra_info) { { event: 'explosion', size: :massive } }

      before do
        allow(exception).to receive(:sentry_extra_data).and_return(extra_info)
      end

      it 'includes the extra data from the exception in the tracking information' do
        track_exception

        expect(Sentry).to have_received(:capture_exception).with(
          exception, a_hash_including(extra: a_hash_including(extra_info))
        )
      end
    end

    context 'the exception implements :sentry_extra_data, which returns nil' do
      let(:extra) { { issue_url: issue_url } }

      before do
        allow(exception).to receive(:sentry_extra_data).and_return(nil)
      end

      it 'just includes the other extra info' do
        track_exception

        expect(Sentry).to have_received(:capture_exception).with(
          exception, a_hash_including(extra: a_hash_including(extra))
        )
      end
    end

    context 'when the error is kind of an `ActiveRecord::StatementInvalid`' do
      let(:exception) { ActiveRecord::StatementInvalid.new(sql: 'SELECT "users".* FROM "users" WHERE "users"."id" = 1 AND "users"."foo" = $1') }

      it 'injects the normalized sql query into extra' do
        track_exception

        expect(sentry_event.extra[:sql]).to eq('SELECT "users".* FROM "users" WHERE "users"."id" = $2 AND "users"."foo" = $1')
      end
    end

    context 'when the `ActiveRecord::StatementInvalid` is wrapped in another exception' do
      it 'injects the normalized sql query into extra' do
        allow(exception).to receive(:cause).and_return(ActiveRecord::StatementInvalid.new(sql: 'SELECT "users".* FROM "users" WHERE "users"."id" = 1 AND "users"."foo" = $1'))

        track_exception

        expect(sentry_event.extra[:sql]).to eq('SELECT "users".* FROM "users" WHERE "users"."id" = $2 AND "users"."foo" = $1')
      end
    end
  end

  context 'event processors' do
    subject(:track_exception) { described_class.track_exception(exception, extra) }

    before do
      allow(Sentry).to receive(:capture_exception).and_call_original
      allow(Gitlab::ErrorTracking::Logger).to receive(:error)
    end

    context 'custom GitLab context when using Sentry.capture_exception directly' do
      subject(:track_exception) { Sentry.capture_exception(exception) }

      it 'merges a default set of tags into the existing tags' do
        Sentry.set_tags(foo: 'bar')

        track_exception

        expect(sentry_event.tags).to include(:correlation_id, :feature_category, :foo, :locale, :program)
      end

      it 'merges the current user information into the existing user information' do
        Sentry.set_user(id: -1)

        track_exception

        expect(sentry_event.user).to eq(id: -1, username: user.username)
      end
    end

    context 'with sidekiq args' do
      context 'when the args does not have anything sensitive' do
        let(:extra) { { sidekiq: { 'class' => 'PostReceive', 'args' => [1, { 'id' => 2, 'name' => 'hello' }, 'some-value', 'another-value'] } } }

        it 'ensures extra.sidekiq.args is a string' do
          track_exception

          expect(Gitlab::ErrorTracking::Logger).to have_received(:error).with(
            hash_including(
              'extra.sidekiq' => {
                'class' => 'PostReceive',
                'args' => ['1', '{"id"=>2, "name"=>"hello"}', 'some-value', 'another-value']
              }
            )
          )
        end

        it 'does not filter parameters when sending to Sentry' do
          track_exception

          expect(sentry_event.extra[:sidekiq]['args']).to eq([1, { 'id' => 2, 'name' => 'hello' }, 'some-value', 'another-value'])
        end
      end

      context 'when the args has sensitive information' do
        let(:extra) { { sidekiq: { 'class' => 'UnknownWorker', 'args' => ['sensitive string', 1, 2] } } }

        it 'filters sensitive arguments before sending and logging' do
          track_exception

          expect(sentry_event.extra[:sidekiq]['args']).to eq(['[FILTERED]', 1, 2])
          expect(Gitlab::ErrorTracking::Logger).to have_received(:error).with(
            hash_including(
              'extra.sidekiq' => {
                'class' => 'UnknownWorker',
                'args' => ['[FILTERED]', '1', '2']
              }
            )
          )
        end
      end
    end

    context 'when the error is a GRPC error' do
      context 'when the GRPC error contains a debug_error_string value' do
        let(:exception) { GRPC::DeadlineExceeded.new('unknown cause', {}, '{"hello":1}') }

        it 'sets the GRPC debug error string in the Sentry event and adds a custom fingerprint' do
          track_exception

          expect(sentry_event.extra[:grpc_debug_error_string]).to eq('{"hello":1}')
          expect(sentry_event.fingerprint).to eq(['GRPC::DeadlineExceeded', '4:unknown cause.'])
        end
      end

      context 'when the GRPC error does not contain a debug_error_string value' do
        let(:exception) { GRPC::DeadlineExceeded.new }

        it 'does not do any processing on the event' do
          track_exception

          expect(sentry_event.extra).not_to include(:grpc_debug_error_string)
          expect(sentry_event.fingerprint).to eq(['GRPC::DeadlineExceeded', '4:unknown cause'])
        end
      end
    end
  end
end
