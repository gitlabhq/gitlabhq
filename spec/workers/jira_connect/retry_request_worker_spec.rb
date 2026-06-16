# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JiraConnect::RetryRequestWorker, feature_category: :integrations do
  using RSpec::Parameterized::TableSyntax

  describe '#perform' do
    let(:jwt) { 'some-jwt' }
    let(:event_url) { 'https://example.com/somewhere' }
    let(:attempts) { 3 }

    subject(:perform) { described_class.new.perform(event_url, jwt, attempts) }

    it 'sends the request, with the appropriate headers' do
      expect(described_class).not_to receive(:perform_in)

      stub_request(:post, event_url)

      perform

      expect(WebMock).to have_requested(:post, event_url).with(headers: { 'Authorization' => 'JWT some-jwt' })
    end

    context 'when the proxied request fails with a transient 5xx' do
      before do
        stub_request(:post, event_url).to_return(status: 500, body: '', headers: {})
      end

      it 'uses a short delay on the first retry' do
        expect(described_class).to receive(:perform_in).with(30.seconds, event_url, jwt, attempts - 1, attempts)

        perform
      end

      context 'with progressively longer delays per remaining attempt' do
        where(:remaining, :expected_delay) do
          3 | 30.seconds
          2 | 5.minutes
          1 | 30.minutes
        end

        with_them do
          it 'schedules the next retry with the expected delay' do
            expect(described_class).to receive(:perform_in).with(expected_delay, event_url, jwt, remaining - 1, 3)

            described_class.new.perform(event_url, jwt, remaining, 3)
          end
        end
      end

      it 'walks the retry chain end-to-end, decrementing remaining_attempts each step' do
        expected_chain = [
          [30.seconds, event_url, jwt, 2, 3],
          [5.minutes,  event_url, jwt, 1, 3],
          [30.minutes, event_url, jwt, 0, 3]
        ]

        current_perform_args = [event_url, jwt]

        expected_chain.each do |expected_perform_in_args|
          captured = nil
          allow(described_class).to receive(:perform_in) { |*args| captured = args }

          described_class.new.perform(*current_perform_args)

          expect(captured).to eq(expected_perform_in_args)
          current_perform_args = captured[1..]
        end
      end

      context 'when there are no more attempts left' do
        let(:attempts) { 0 }

        it 'does not retry and logs the dropped request' do
          expect(described_class).not_to receive(:perform_in)
          expect(Gitlab::AppLogger).to receive(:error).with(
            hash_including(
              message: 'JiraConnect::RetryRequestWorker dropped request',
              proxy_url: event_url,
              reason: 'HTTP 500'
            )
          )

          perform
        end
      end
    end

    context 'when the proxied request returns 429 Too Many Requests' do
      before do
        stub_request(:post, event_url).to_return(status: 429)
      end

      it 'retries with the first backoff delay' do
        expect(described_class).to receive(:perform_in).with(30.seconds, event_url, jwt, attempts - 1, attempts)

        perform
      end
    end

    context 'when the proxied request returns a non-retryable 4xx' do
      where(:status) do
        [400, 401, 403, 404, 422]
      end

      with_them do
        before do
          stub_request(:post, event_url).to_return(status: status)
        end

        it 'does not retry and logs the dropped request' do
          expect(described_class).not_to receive(:perform_in)
          expect(Gitlab::AppLogger).to receive(:error).with(
            hash_including(
              message: 'JiraConnect::RetryRequestWorker dropped request',
              proxy_url: event_url,
              reason: "HTTP #{status}"
            )
          )

          perform
        end
      end
    end

    context 'when the request raises a network error' do
      before do
        stub_request(:post, event_url).to_raise(Net::OpenTimeout)
      end

      it 'retries with the first backoff delay' do
        expect(described_class).to receive(:perform_in).with(30.seconds, event_url, jwt, attempts - 1, attempts)

        perform
      end

      context 'when there are no more attempts left' do
        let(:attempts) { 0 }

        it 'does not retry and logs the dropped request' do
          expect(described_class).not_to receive(:perform_in)
          expect(Gitlab::AppLogger).to receive(:error).with(
            hash_including(
              message: 'JiraConnect::RetryRequestWorker dropped request',
              proxy_url: event_url,
              reason: 'Net::OpenTimeout'
            )
          )

          perform
        end
      end
    end

    context 'when remaining_attempts exceeds total_attempts' do
      before do
        stub_request(:post, event_url).to_return(status: 500)
      end

      it 'clamps to the last delay rather than wrapping to a negative index' do
        # retry_index would be -2 without clamping; Ruby would return RETRY_DELAYS[-2] = 5.minutes.
        expect(described_class).to receive(:perform_in).with(30.minutes, event_url, jwt, 4, 3)

        described_class.new.perform(event_url, jwt, 5, 3)
      end
    end

    context 'with a caller-supplied smaller total_attempts' do
      before do
        stub_request(:post, event_url).to_return(status: 500)
      end

      it 'starts the schedule from the first delay regardless of INITIAL_ATTEMPTS' do
        # Caller intentionally allots 2 attempts. First retry should still be 30s, not 5min.
        expect(described_class).to receive(:perform_in).with(30.seconds, event_url, jwt, 1, 2)

        described_class.new.perform(event_url, jwt, 2, 2)
      end
    end
  end
end
