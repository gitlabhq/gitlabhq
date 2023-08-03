# frozen_string_literal: true

RSpec.shared_examples 'a hook that gets automatically disabled on failure' do
  let(:logger) { instance_double('Gitlab::WebHooks::Logger') }

  before do
    allow(hook).to receive(:logger).and_return(logger)
    allow(logger).to receive(:info)
  end

  shared_examples 'is tolerant of invalid records' do
    specify do
      hook.url = nil

      expect(hook).to be_invalid
      run_expectation
    end
  end

  describe '.executable/.disabled', :freeze_time do
    let!(:not_executable) do
      [
        [4, nil], # Exceeded the grace period, set by #fail!
        [4, 1.second.from_now], # Exceeded the grace period, set by #backoff!
        [4, Time.current] # Exceeded the grace period, set by #backoff!, edge-case
      ].map do |(recent_failures, disabled_until)|
        create(
          hook_factory,
          **default_factory_arguments,
          recent_failures: recent_failures,
          disabled_until: disabled_until
        )
      end
    end

    let!(:executables) do
      expired = 1.second.ago
      borderline = Time.current
      suspended = 1.second.from_now

      [
        # Most of these are impossible states, but are included for completeness
        [0, nil],
        [1, nil],
        [3, nil],
        [4, expired],

        # Impossible cases:
        [3, suspended],
        [3, expired],
        [3, borderline],
        [1, suspended],
        [1, expired],
        [1, borderline],
        [0, borderline],
        [0, suspended],
        [0, expired]
      ].map do |(recent_failures, disabled_until)|
        create(
          hook_factory,
          **default_factory_arguments,
          recent_failures: recent_failures,
          disabled_until: disabled_until
        )
      end
    end

    it 'finds the correct set of project hooks' do
      expect(find_hooks.executable).to match_array executables
      expect(find_hooks.executable).to all(be_executable)

      # As expected, and consistent
      expect(find_hooks.disabled).to match_array not_executable
      expect(find_hooks.disabled.map(&:executable?)).not_to include(true)

      # Nothing is missing
      expect(find_hooks.executable.to_a + find_hooks.disabled.to_a).to match_array(find_hooks.to_a)
    end

    context 'when the flag is disabled' do
      before do
        stub_feature_flags(auto_disabling_web_hooks: false)
      end

      it 'causes all hooks to be considered executable' do
        expect(find_hooks.executable.count).to eq(16)
      end

      it 'causes no hooks to be considered disabled' do
        expect(find_hooks.disabled).to be_empty
      end
    end

    context 'when silent mode is enabled' do
      before do
        stub_application_setting(silent_mode_enabled: true)
      end

      it 'causes no hooks to be considered executable' do
        expect(find_hooks.executable).to be_empty
      end

      it 'causes all hooks to be considered disabled' do
        expect(find_hooks.disabled.count).to eq(16)
      end
    end
  end

  describe '#executable?', :freeze_time do
    let(:web_hook) { create(hook_factory, **default_factory_arguments) }

    where(:recent_failures, :not_until, :executable) do
      [
        [0, :not_set, true],
        [0, :past,    true],
        [0, :future,  true],
        [0, :now,     true],
        [1, :not_set, true],
        [1, :past,    true],
        [1, :future,  true],
        [3, :not_set, true],
        [3, :past,    true],
        [3, :future,  true],
        [4, :not_set, false],
        [4, :past,    true], # expired suspension
        [4, :now,     false], # active suspension
        [4, :future,  false] # active suspension
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
        expect(web_hook.executable?).to eq(executable)
      end

      context 'when the flag is disabled' do
        before do
          stub_feature_flags(auto_disabling_web_hooks: false)
        end

        it 'is always executable' do
          expect(web_hook).to be_executable
        end
      end
    end
  end

  describe '#enable!' do
    it 'makes a hook executable if it was marked as failed' do
      hook.recent_failures = 1000

      expect { hook.enable! }.to change { hook.executable? }.from(false).to(true)
    end

    it 'makes a hook executable if it is currently backed off' do
      hook.recent_failures = 1000
      hook.disabled_until = 1.hour.from_now

      expect { hook.enable! }.to change { hook.executable? }.from(false).to(true)
    end

    it 'logs relevant information' do
      hook.recent_failures = 1000
      hook.disabled_until = 1.hour.from_now

      expect(logger)
        .to receive(:info)
        .with(a_hash_including(
          hook_id: hook.id,
          action: 'enable',
          recent_failures: 0,
          disabled_until: nil,
          backoff_count: 0
        ))

      hook.enable!
    end

    it 'does not update hooks unless necessary' do
      hook

      sql_count = ActiveRecord::QueryRecorder.new { hook.enable! }.count

      expect(sql_count).to eq(0)
    end

    include_examples 'is tolerant of invalid records' do
      def run_expectation
        hook.recent_failures = 1000

        expect { hook.enable! }.to change { hook.executable? }.from(false).to(true)
      end
    end
  end

  describe '#backoff!', :freeze_time do
    context 'when we have not backed off before' do
      it 'does not disable the hook' do
        expect { hook.backoff! }.not_to change { hook.executable? }.from(true)
      end

      it 'increments recent_failures' do
        expect { hook.backoff! }.to change { hook.recent_failures }.from(0).to(1)
      end

      it 'logs relevant information' do
        expect(logger)
          .to receive(:info)
          .with(a_hash_including(
            hook_id: hook.id, action: 'backoff', recent_failures: 1
          ))

        hook.backoff!
      end
    end

    context 'when we have exhausted the grace period' do
      before do
        hook.update!(recent_failures: WebHooks::AutoDisabling::FAILURE_THRESHOLD)
      end

      it 'disables the hook' do
        expect { hook.backoff! }.to change { hook.executable? }.from(true).to(false)
      end

      it 'increments backoff_count' do
        expect { hook.backoff! }.to change { hook.backoff_count }.from(0).to(1)
      end

      it 'sets disabled_until' do
        expect { hook.backoff! }.to change { hook.disabled_until }.from(nil).to(1.minute.from_now)
      end

      it 'logs relevant information' do
        expect(logger)
          .to receive(:info)
          .with(a_hash_including(
            hook_id: hook.id,
            action: 'backoff',
            recent_failures: WebHooks::AutoDisabling::FAILURE_THRESHOLD + 1,
            disabled_until: 1.minute.from_now,
            backoff_count: 1
          ))

        hook.backoff!
      end

      context 'when the hook is permanently disabled' do
        before do
          allow(hook).to receive(:permanently_disabled?).and_return(true)
        end

        it 'does not set disabled_until' do
          expect { hook.backoff! }.not_to change { hook.disabled_until }
        end

        it 'does not increment the backoff count' do
          expect { hook.backoff! }.not_to change { hook.backoff_count }
        end
      end

      include_examples 'is tolerant of invalid records' do
        def run_expectation
          expect { hook.backoff! }.to change { hook.backoff_count }.by(1)
        end
      end

      context 'when the flag is disabled' do
        before do
          stub_feature_flags(auto_disabling_web_hooks: false)
        end

        it 'does not increment backoff count' do
          expect { hook.failed! }.not_to change { hook.backoff_count }
        end
      end
    end
  end

  describe '#failed!' do
    include_examples 'is tolerant of invalid records' do
      def run_expectation
        expect { hook.failed! }.to change { hook.recent_failures }.by(1)
      end

      context 'when the flag is disabled' do
        before do
          stub_feature_flags(auto_disabling_web_hooks: false)
        end

        it 'does not increment recent failure count' do
          expect { hook.failed! }.not_to change { hook.recent_failures }
        end
      end
    end
  end

  describe '#temporarily_disabled?' do
    it 'is false when not temporarily disabled' do
      expect(hook).not_to be_temporarily_disabled
    end

    it 'allows FAILURE_THRESHOLD initial failures before we back-off' do
      WebHooks::AutoDisabling::FAILURE_THRESHOLD.times do
        hook.backoff!
        expect(hook).not_to be_temporarily_disabled
      end

      hook.backoff!
      expect(hook).to be_temporarily_disabled
    end

    context 'when hook has been told to back off' do
      before do
        hook.update!(recent_failures: WebHooks::AutoDisabling::FAILURE_THRESHOLD)
        hook.backoff!
      end

      it 'is true' do
        expect(hook).to be_temporarily_disabled
      end

      context 'when the flag is disabled' do
        before do
          stub_feature_flags(auto_disabling_web_hooks: false)
        end

        it 'is false' do
          expect(hook).not_to be_temporarily_disabled
        end
      end
    end
  end

  describe '#permanently_disabled?' do
    it 'is false when not disabled' do
      expect(hook).not_to be_permanently_disabled
    end

    context 'when hook has been disabled' do
      before do
        hook.update!(recent_failures: WebHooks::AutoDisabling::EXCEEDED_FAILURE_THRESHOLD)
      end

      it 'is true' do
        expect(hook).to be_permanently_disabled
      end

      context 'when the flag is disabled' do
        before do
          stub_feature_flags(auto_disabling_web_hooks: false)
        end

        it 'is false' do
          expect(hook).not_to be_permanently_disabled
        end
      end
    end
  end

  describe '#alert_status' do
    subject(:status) { hook.alert_status }

    it { is_expected.to eq :executable }

    context 'when hook has been disabled' do
      before do
        hook.update!(recent_failures: WebHooks::AutoDisabling::EXCEEDED_FAILURE_THRESHOLD)
      end

      it { is_expected.to eq :disabled }

      context 'when the flag is disabled' do
        before do
          stub_feature_flags(auto_disabling_web_hooks: false)
        end

        it { is_expected.to eq(:executable) }
      end
    end

    context 'when hook has been backed off' do
      before do
        hook.update!(recent_failures: WebHooks::AutoDisabling::EXCEEDED_FAILURE_THRESHOLD)
        hook.disabled_until = 1.hour.from_now
      end

      it { is_expected.to eq :temporarily_disabled }

      context 'when the flag is disabled' do
        before do
          stub_feature_flags(auto_disabling_web_hooks: false)
        end

        it { is_expected.to eq(:executable) }
      end
    end
  end
end
