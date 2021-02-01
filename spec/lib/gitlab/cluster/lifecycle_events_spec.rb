# frozen_string_literal: true

require 'fast_spec_helper'
require 'rspec-parameterized'

RSpec.describe Gitlab::Cluster::LifecycleEvents do
  # we create a new instance to ensure that we do not touch existing hooks
  let(:replica) { Class.new(described_class) }

  context 'hooks execution' do
    using RSpec::Parameterized::TableSyntax

    where(:method, :hook_names) do
      :do_worker_start             | %i[worker_start_hooks]
      :do_before_fork              | %i[before_fork_hooks]
      :do_before_graceful_shutdown | %i[master_blackout_period master_graceful_shutdown]
      :do_before_master_restart    | %i[master_restart_hooks]
    end

    before do
      # disable blackout period to speed-up tests
      stub_config(shutdown: { blackout_seconds: 0 })
    end

    with_them do
      subject { replica.public_send(method) }

      it 'executes all hooks' do
        hook_names.each do |hook_name|
          hook = double
          replica.instance_variable_set(:"@#{hook_name}", [hook])

          # ensure that proper hooks are called
          expect(hook).to receive(:call)
          expect(replica).to receive(:call).with(hook_name, anything).and_call_original
        end

        subject
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
