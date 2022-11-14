# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Cluster::LifecycleEvents do
  using RSpec::Parameterized::TableSyntax

  # we create a new instance to ensure that we do not touch existing hooks
  let(:replica) { Class.new(described_class) }

  before do
    # disable blackout period to speed-up tests
    stub_config(shutdown: { blackout_seconds: 0 })
  end

  context 'outside of clustered environments' do
    where(:hook, :was_executed_immediately) do
      :on_worker_start             | true
      :on_before_fork              | false
      :on_before_graceful_shutdown | false
      :on_before_master_restart    | false
      :on_worker_stop              | false
    end

    with_them do
      it 'executes the given block immediately' do
        was_executed = false
        replica.public_send(hook, &proc { was_executed = true })

        expect(was_executed).to eq(was_executed_immediately)
      end
    end
  end

  context 'in clustered environments' do
    before do
      allow(Gitlab::Runtime).to receive(:puma?).and_return(true)
      replica.set_puma_options(workers: 2)
    end

    where(:hook, :execution_helper) do
      :on_worker_start             | :do_worker_start
      :on_before_fork              | :do_before_fork
      :on_before_graceful_shutdown | :do_before_graceful_shutdown
      :on_before_master_restart    | :do_before_master_restart
      :on_worker_stop              | :do_worker_stop
    end

    with_them do
      it 'requires explicit execution via do_* helper' do
        was_executed = false
        replica.public_send(hook, &proc { was_executed = true })

        expect { replica.public_send(execution_helper) }.to change { was_executed }.from(false).to(true)
      end
    end
  end

  describe '#call' do
    let(:name) { :my_hooks }

    subject { replica.send(:call, name, hooks) }

    context 'when many hooks raise exception' do
      let(:hooks) do
        [
          -> { raise 'Exception A' },
          -> { raise 'Exception B' }
        ]
      end

      context 'USE_FATAL_LIFECYCLE_EVENTS is set to default' do
        it 'only first hook is executed and is fatal' do
          expect(hooks[0]).to receive(:call).and_call_original
          expect(hooks[1]).not_to receive(:call)

          expect(Gitlab::ErrorTracking).to receive(:track_exception).and_call_original
          expect(replica).to receive(:warn).with('ERROR: The hook my_hooks failed with exception (RuntimeError) "Exception A".')

          expect { subject }.to raise_error(described_class::FatalError, 'Exception A')
        end
      end

      context 'when USE_FATAL_LIFECYCLE_EVENTS is disabled' do
        before do
          stub_const('Gitlab::Cluster::LifecycleEvents::USE_FATAL_LIFECYCLE_EVENTS', false)
        end

        it 'many hooks are executed and all exceptions are logged' do
          expect(hooks[0]).to receive(:call).and_call_original
          expect(hooks[1]).to receive(:call).and_call_original

          expect(Gitlab::ErrorTracking).to receive(:track_exception).twice.and_call_original
          expect(replica).to receive(:warn).twice.and_call_original

          expect { subject }.not_to raise_error
        end
      end
    end
  end
end
