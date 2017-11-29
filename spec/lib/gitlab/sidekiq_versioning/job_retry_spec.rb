require 'spec_helper'

describe Gitlab::SidekiqVersioning::JobRetry, :sidekiq, :redis do
  before do
    Sidekiq::JobRetry.prepend described_class
  end

  subject { Sidekiq::JobRetry.new }

  let(:job) { { 'class' => 'Foo::BarWorker', 'retry' => true, 'queue' => queue } }
  let(:queue) { 'unknown' }

  describe '#global' do
    def global!
      subject.global(job, queue, &block)
    end

    context 'when an error is raised' do
      let(:block) { -> { job['class'].constantize } }

      context 'when the worker class is unknown' do
        context 'when SidekiqVersioning.requeue_unsupported_job returns true' do
          it 'calls SidekiqVersioning.requeue_unsupported_job and skips the retry' do
            expect(Gitlab::SidekiqVersioning).to receive(:requeue_unsupported_job).with(nil, job, queue).and_return(true)

            expect(subject).not_to receive(:attempt_retry)

            expect { global! }.to raise_error(Sidekiq::JobRetry::Skip)
          end
        end

        context 'when SidekiqVersioning.requeue_unsupported_job returns false' do
          it 'callscall SidekiqVersioning.requeue_unsupported_job, retries, and bubbles up the error' do
            expect(Gitlab::SidekiqVersioning).to receive(:requeue_unsupported_job).with(nil, job, queue).and_return(false)

            expect(subject).to receive(:attempt_retry)

            expect { global! }.to raise_error(NameError)
          end
        end
      end

      context 'when an unrelated error is raised' do
        let(:block) { -> { 'SomethingUnrelated'.constantize } }

        it 'does not call SidekiqVersioning.requeue_unsupported_job, retries, and bubbles up the error' do
          expect(Gitlab::SidekiqVersioning).not_to receive(:requeue_unsupported_job)

          expect(subject).to receive(:attempt_retry)

          expect { global! }.to raise_error(NameError)
        end
      end
    end

    context 'when no errors are raised' do
      let(:block) { -> { true } }

      it 'does not call SidekiqVersioning.requeue_unsupported_job' do
        expect(Gitlab::SidekiqVersioning).not_to receive(:requeue_unsupported_job)

        global!
      end
    end
  end
end
