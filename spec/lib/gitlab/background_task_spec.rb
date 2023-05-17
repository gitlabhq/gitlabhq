# frozen_string_literal: true

require 'spec_helper'

# We need to capture task state from a closure, which requires instance variables.
# rubocop: disable RSpec/InstanceVariable
RSpec.describe Gitlab::BackgroundTask, feature_category: :build do
  let(:options) { {} }
  let(:task) do
    proc do
      @task_run = true
      @task_thread = Thread.current
    end
  end

  subject(:background_task) { described_class.new(task, **options) }

  def expect_condition
    Timeout.timeout(3) do
      sleep 0.1 until yield
    end
  end

  context 'when stopped' do
    it 'is not running' do
      expect(background_task).not_to be_running
    end

    describe '#start' do
      it 'runs the given task on a background thread' do
        test_thread = Thread.current

        background_task.start

        expect_condition { @task_run == true }
        expect_condition { @task_thread != test_thread }
        expect(background_task).to be_running
      end

      it 'returns self' do
        expect(background_task.start).to be(background_task)
      end

      context 'when installing exit handler' do
        it 'stops a running background task' do
          expect(background_task).to receive(:at_exit).and_yield

          background_task.start

          expect(background_task).not_to be_running
        end
      end

      context 'when task responds to start' do
        let(:task_class) do
          Struct.new(:started, :start_retval, :run) do
            def start
              self.started = true
              self.start_retval
            end

            def call
              self.run = true
            end
          end
        end

        let(:task) { task_class.new }

        it 'calls start' do
          background_task.start

          expect_condition { task.started == true }
        end

        context 'when start returns true' do
          it 'runs the task' do
            task.start_retval = true

            background_task.start

            expect_condition { task.run == true }
          end
        end

        context 'when start returns false' do
          it 'does not run the task' do
            task.start_retval = false

            background_task.start

            expect_condition { task.run.nil? }
          end
        end
      end

      context 'when synchronous is set to true' do
        let(:options) { { synchronous: true } }

        it 'calls join on the thread' do
          # Thread has to be run in a block, expect_next_instance_of does not support this.
          allow_any_instance_of(Thread).to receive(:join) # rubocop:disable RSpec/AnyInstanceOf

          background_task.start

          expect_condition { @task_run == true }
          expect(@task_thread).to have_received(:join)
        end
      end
    end

    describe '#stop' do
      it 'is a no-op' do
        expect { background_task.stop }.not_to change { subject.running? }
        expect_condition { @task_run.nil? }
      end
    end
  end

  context 'when running' do
    before do
      background_task.start
    end

    describe '#start' do
      it 'raises an error' do
        expect { background_task.start }.to raise_error(described_class::AlreadyStartedError)
      end
    end

    describe '#stop' do
      it 'stops running' do
        expect { background_task.stop }.to change { subject.running? }.from(true).to(false)
      end

      context 'when task responds to stop' do
        let(:task_class) do
          Struct.new(:stopped, :call) do
            def stop
              self.stopped = true
            end
          end
        end

        let(:task) { task_class.new }

        it 'calls stop' do
          background_task.stop

          expect_condition { task.stopped == true }
        end
      end

      context 'when task stop raises an error' do
        let(:error) { RuntimeError.new('task error') }
        let(:options) { { name: 'test_background_task' } }

        let(:task_class) do
          Struct.new(:call, :error, keyword_init: true) do
            def stop
              raise error
            end
          end
        end

        let(:task) { task_class.new(error: error) }

        it 'stops gracefully' do
          expect { background_task.stop }.not_to raise_error
          expect(background_task).not_to be_running
        end

        it 'reports the error' do
          expect(Gitlab::ErrorTracking).to receive(:track_exception).with(
            error, { extra: { reported_by: 'test_background_task' } }
          )

          background_task.stop
        end
      end
    end

    context 'when task run raises exception' do
      let(:error) { RuntimeError.new('task error') }
      let(:options) { { name: 'test_background_task' } }
      let(:task) do
        proc do
          @task_run = true
          raise error
        end
      end

      it 'stops gracefully' do
        expect_condition { @task_run == true }
        expect { background_task.stop }.not_to raise_error
        expect(background_task).not_to be_running
      end

      it 'reports the error' do
        expect(Gitlab::ErrorTracking).to receive(:track_exception).with(
          error, { extra: { reported_by: 'test_background_task' } }
        )

        background_task.stop
      end
    end
  end
end
# rubocop: enable RSpec/InstanceVariable
