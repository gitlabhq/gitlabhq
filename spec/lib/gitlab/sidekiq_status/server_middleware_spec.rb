# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SidekiqStatus::ServerMiddleware do
  describe '#call' do
    let(:jid) { '123' }
    let(:worker) { instance_double(ApplicationWorker) }
    let(:queue) { 'default' }

    context 'when job is a success' do
      it 'stops tracking of a job upon completion' do
        expect(Gitlab::SidekiqStatus).to receive(:unset).with(jid)

        ret = described_class.new
          .call(worker, { 'jid' => jid }, queue) { 10 }

        expect(ret).to eq(10)
      end
    end

    context 'when job raises an exception' do
      context 'when retry is not configured' do
        it 'stops tracking the job' do
          expect(Gitlab::SidekiqStatus).to receive(:unset).with(jid)

          expect do
            described_class.new
              .call(worker, { 'jid' => jid }, queue) { raise StandardError, "Failed" }
          end.to raise_error(StandardError, "Failed")
        end
      end

      context 'when retry is configured and retries remain' do
        it 'does not clear the jid so that it survives the retry wait period' do
          expect(Gitlab::SidekiqStatus).not_to receive(:unset)

          expect do
            described_class.new
              .call(worker, { 'jid' => jid, 'retry' => 3 }, queue) { raise StandardError, "Failed" }
          end.to raise_error(StandardError, "Failed")
        end

        it 'does not clear the jid on intermediate retries' do
          expect(Gitlab::SidekiqStatus).not_to receive(:unset)

          expect do
            described_class.new
              .call(worker, { 'jid' => jid, 'retry' => 3, 'retry_count' => 1 }, queue) { raise StandardError, "Failed" }
          end.to raise_error(StandardError, "Failed")
        end
      end

      context 'when retry is configured but retries are exhausted' do
        it 'stops tracking the job' do
          expect(Gitlab::SidekiqStatus).to receive(:unset).with(jid)

          expect do
            described_class.new
              .call(worker, { 'jid' => jid, 'retry' => 3, 'retry_count' => 2 }, queue) { raise StandardError, "Failed" }
          end.to raise_error(StandardError, "Failed")
        end
      end

      context 'when retry is set to false' do
        it 'stops tracking the job' do
          expect(Gitlab::SidekiqStatus).to receive(:unset).with(jid)

          expect do
            described_class.new
              .call(worker, { 'jid' => jid, 'retry' => false }, queue) { raise StandardError, "Failed" }
          end.to raise_error(StandardError, "Failed")
        end
      end

      context 'when retry is set to 0' do
        it 'stops tracking the job' do
          expect(Gitlab::SidekiqStatus).to receive(:unset).with(jid)

          expect do
            described_class.new
              .call(worker, { 'jid' => jid, 'retry' => 0 }, queue) { raise StandardError, "Failed" }
          end.to raise_error(StandardError, "Failed")
        end
      end

      context 'when retry is set to true (non-integer, uses default configuration)' do
        let(:sidekiq_config) { instance_double(Sidekiq::Config) }

        before do
          allow(Sidekiq).to receive(:default_configuration).and_return(sidekiq_config)
          allow(sidekiq_config).to receive(:[]).with(:max_retries).and_return(3)
        end

        context 'when retries remain' do
          it 'does not clear the jid so that it survives the retry wait period' do
            expect(Gitlab::SidekiqStatus).not_to receive(:unset)

            expect do
              described_class.new
                .call(worker, { 'jid' => jid, 'retry' => true }, queue) { raise StandardError, "Failed" }
            end.to raise_error(StandardError, "Failed")
          end
        end

        context 'when retries are exhausted' do
          it 'stops tracking the job' do
            expect(Gitlab::SidekiqStatus).to receive(:unset).with(jid)

            expect do
              described_class.new
                .call(worker, { 'jid' => jid, 'retry' => true,
'retry_count' => 2 }, queue) { raise StandardError, "Failed" }
            end.to raise_error(StandardError, "Failed")
          end
        end
      end

      context 'when Sidekiq.default_configuration does not set max_retries' do
        let(:sidekiq_config) { instance_double(Sidekiq::Config) }

        before do
          allow(Sidekiq).to receive(:default_configuration).and_return(sidekiq_config)
          allow(sidekiq_config).to receive(:[]).with(:max_retries).and_return(nil)
        end

        context 'when retries remain' do
          it 'does not clear the jid, falling back to DEFAULT_MAX_RETRY_ATTEMPTS' do
            expect(Gitlab::SidekiqStatus).not_to receive(:unset)

            expect do
              described_class.new
                .call(worker, { 'jid' => jid, 'retry' => true }, queue) { raise StandardError, "Failed" }
            end.to raise_error(StandardError, "Failed")
          end
        end

        context 'when retries are exhausted using DEFAULT_MAX_RETRY_ATTEMPTS' do
          it 'stops tracking the job' do
            stub_const('Sidekiq::JobRetry::DEFAULT_MAX_RETRY_ATTEMPTS', 3)

            expect(Gitlab::SidekiqStatus).to receive(:unset).with(jid)

            expect do
              described_class.new
                .call(worker, { 'jid' => jid, 'retry' => true,
'retry_count' => 2 }, queue) { raise StandardError, "Failed" }
            end.to raise_error(StandardError, "Failed")
          end
        end
      end
    end

    context 'when job is interrupted by Sidekiq shutdown' do
      it 'does not clear the jid so that it survives re-enqueue' do
        expect(Gitlab::SidekiqStatus).not_to receive(:unset)

        expect do
          described_class.new
            .call(worker, { 'jid' => jid }, queue) { raise Sidekiq::Shutdown }
        end.to raise_error(Sidekiq::Shutdown)
      end
    end

    context 'when job is deferred' do
      it 'does not clear the jid so that it survives the deferral' do
        expect(Gitlab::SidekiqStatus).not_to receive(:unset)

        described_class.new
          .call(worker, { 'jid' => jid, 'deferred' => true }, queue) { nil }
      end
    end
  end
end
