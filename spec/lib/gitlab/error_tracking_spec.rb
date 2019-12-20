# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::ErrorTracking do
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

  before do
    stub_sentry_settings

    allow(described_class).to receive(:sentry_dsn).and_return(Gitlab.config.sentry.dsn)
    allow(Labkit::Correlation::CorrelationId).to receive(:current_id).and_return('cid')

    described_class.configure
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
    it 'calls Raven.capture_exception' do
      expected_extras = {
        some_other_info: 'info',
        issue_url: issue_url
      }

      expected_tags = {
        correlation_id: 'cid'
      }

      expect(Raven).to receive(:capture_exception)
                         .with(exception,
                          tags: a_hash_including(expected_tags),
                          extra: a_hash_including(expected_extras))

      described_class.track_exception(
        exception,
        issue_url: issue_url,
        some_other_info: 'info'
      )
    end

    it 'calls Gitlab::ErrorTracking::Logger.error with formatted payload' do
      expect(Gitlab::ErrorTracking::Logger).to receive(:error)
        .with(a_hash_including(*expected_payload_includes))

      described_class.track_exception(
        exception,
        issue_url: issue_url,
        some_other_info: 'info'
      )
    end

    context 'the exception implements :sentry_extra_data' do
      let(:extra_info) { { event: 'explosion', size: :massive } }
      let(:exception) { double(message: 'bang!', sentry_extra_data: extra_info, backtrace: caller) }

      it 'includes the extra data from the exception in the tracking information' do
        expect(Raven).to receive(:capture_exception)
          .with(exception, a_hash_including(extra: a_hash_including(extra_info)))

        described_class.track_exception(exception)
      end
    end

    context 'the exception implements :sentry_extra_data, which returns nil' do
      let(:exception) { double(message: 'bang!', sentry_extra_data: nil, backtrace: caller) }

      it 'just includes the other extra info' do
        extra_info = { issue_url: issue_url }
        expect(Raven).to receive(:capture_exception)
          .with(exception, a_hash_including(extra: a_hash_including(extra_info)))

        described_class.track_exception(exception, extra_info)
      end
    end
  end
end
