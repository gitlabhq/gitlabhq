# frozen_string_literal: true

RSpec.shared_examples 'a hook that does not get automatically disabled on failure' do
  describe '.executable/.disabled', :freeze_time do
    let(:attributes_for_webhooks) do
      attributes_list = attributes_for_list(hook_factory, 13)

      merged_attributes = attributes_list.zip([
        [0, Time.current],
        [0, 1.minute.from_now],
        [1, 1.minute.from_now],
        [3, 1.minute.from_now],
        [4, nil],
        [4, 1.day.ago],
        [4, 1.minute.from_now],
        [0, nil],
        [0, 1.day.ago],
        [1, nil],
        [1, 1.day.ago],
        [3, nil],
        [3, 1.day.ago]
      ])

      merged_attributes.map do |attributes, (recent_failures, disabled_until)|
        attributes.merge(**default_factory_arguments, recent_failures: recent_failures, disabled_until: disabled_until)
      end
    end

    let(:webhooks) { described_class.create!(attributes_for_webhooks) }

    it 'finds the correct set of project hooks' do
      expect(find_hooks).to all(be_executable)
      expect(find_hooks.executable).to match_array(webhooks)
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
        expect(find_hooks.disabled).to match_array(webhooks)
      end
    end
  end

  describe '#executable?', :freeze_time do
    let(:web_hook) { build(hook_factory, **default_factory_arguments) }

    where(:recent_failures, :not_until) do
      [
        [0, :not_set],
        [0, :past],
        [0, :future],
        [0, :now],
        [1, :not_set],
        [1, :past],
        [1, :future],
        [3, :not_set],
        [3, :past],
        [3, :future],
        [4, :not_set],
        [4, :past], # expired suspension
        [4, :now], # active suspension
        [4, :future] # active suspension
      ]
    end

    with_them do
      # Phasing means we cannot put these values in the where block,
      # which is not subject to the frozen time context.
      let(:disabled_until) do
        case not_until
        when :not_set
          nil
        when :past
          1.minute.ago
        when :future
          1.minute.from_now
        when :now
          Time.current
        end
      end

      before do
        web_hook.update!(recent_failures: recent_failures, disabled_until: disabled_until)
      end

      it 'has the correct state' do
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
        hook.update!(recent_failures: WebHooks::AutoDisabling::FAILURE_THRESHOLD)
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
      WebHooks::AutoDisabling::FAILURE_THRESHOLD.times do
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

      hook.update!(recent_failures: WebHooks::AutoDisabling::EXCEEDED_FAILURE_THRESHOLD)

      expect(hook).not_to be_permanently_disabled
    end
  end

  describe '#alert_status' do
    subject(:status) { hook.alert_status }

    it { is_expected.to eq :executable }

    context 'when hook has been disabled' do
      before do
        hook.update!(recent_failures: WebHooks::AutoDisabling::EXCEEDED_FAILURE_THRESHOLD)
      end

      it { is_expected.to eq :executable }
    end

    context 'when hook has been backed off' do
      before do
        hook.update!(recent_failures: WebHooks::AutoDisabling::EXCEEDED_FAILURE_THRESHOLD)
        hook.disabled_until = 1.hour.from_now
      end

      it { is_expected.to eq :executable }
    end
  end
end
