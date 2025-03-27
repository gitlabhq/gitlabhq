# frozen_string_literal: true

RSpec.shared_examples 'a hook that does not get automatically disabled on failure' do
  let(:exeeded_failure_threshold) { WebHooks::AutoDisabling::TEMPORARILY_DISABLED_FAILURE_THRESHOLD + 1 }

  describe '.executable/.disabled', :freeze_time do
    include_context 'with webhook auto-disabling failure thresholds'

    with_them do
      let(:web_hook) do
        factory_arguments = default_factory_arguments.merge(
          recent_failures: recent_failures,
          disabled_until: disabled_until
        )

        create(hook_factory, **factory_arguments)
      end

      it 'is always enabled' do
        expect(find_hooks).to all(be_executable)
        expect(find_hooks.executable).to match_array(find_hooks)
        expect(find_hooks.disabled).to be_empty
      end

      context 'when silent mode is enabled' do
        before do
          stub_application_setting(silent_mode_enabled: true)
        end

        it 'causes no hooks to be considered executable' do
          expect(find_hooks.executable).to be_empty
        end

        it 'causes all hooks to be considered disabled' do
          expect(find_hooks.disabled).to match_array(find_hooks)
        end
      end
    end
  end

  describe '#executable?', :freeze_time do
    include_context 'with webhook auto-disabling failure thresholds'

    with_them do
      let(:web_hook) do
        factory_arguments = default_factory_arguments.merge(
          recent_failures: recent_failures,
          disabled_until: disabled_until
        )

        build(hook_factory, **factory_arguments)
      end

      it 'is always executable' do
        expect(web_hook).to be_executable
      end
    end
  end

  describe '#enable!' do
    it 'makes a hook executable if it was marked as failed' do
      hook.recent_failures = 1000

      expect { hook.enable! }.not_to change { hook.executable? }.from(true)
    end

    it 'makes a hook executable if it is currently backed off' do
      hook.recent_failures = 1000
      hook.disabled_until = 1.hour.from_now

      expect { hook.enable! }.not_to change { hook.executable? }.from(true)
    end

    it 'does not update hooks unless necessary' do
      hook

      sql_count = ActiveRecord::QueryRecorder.new { hook.enable! }.count

      expect(sql_count).to eq(0)
    end
  end

  describe '#backoff!' do
    context 'when we have not backed off before' do
      it 'does not disable the hook' do
        expect { hook.backoff! }.not_to change { hook.executable? }.from(true)
      end
    end

    context 'when we have exhausted the grace period' do
      before do
        hook.update!(recent_failures: WebHooks::AutoDisabling::TEMPORARILY_DISABLED_FAILURE_THRESHOLD)
      end

      it 'does not disable the hook' do
        expect { hook.backoff! }.not_to change { hook.executable? }.from(true)
      end
    end
  end

  describe '#temporarily_disabled?' do
    it 'is false' do
      # Initially
      expect(hook).not_to be_temporarily_disabled

      # Backing off
      WebHooks::AutoDisabling::TEMPORARILY_DISABLED_FAILURE_THRESHOLD.times do
        hook.backoff!
        expect(hook).not_to be_temporarily_disabled
      end

      hook.backoff!
      expect(hook).not_to be_temporarily_disabled
    end
  end

  describe '#permanently_disabled?' do
    it 'is false' do
      # Initially
      expect(hook).not_to be_permanently_disabled

      hook.update!(recent_failures: exeeded_failure_threshold)

      expect(hook).not_to be_permanently_disabled
    end
  end

  describe '#alert_status' do
    subject(:status) { hook.alert_status }

    it { is_expected.to eq :executable }

    context 'when hook has been disabled' do
      before do
        hook.update!(recent_failures: exeeded_failure_threshold)
      end

      it { is_expected.to eq :executable }
    end

    context 'when hook has been backed off' do
      before do
        hook.update!(recent_failures: exeeded_failure_threshold)
        hook.disabled_until = 1.hour.from_now
      end

      it { is_expected.to eq :executable }
    end
  end
end
