# frozen_string_literal: true

RSpec.shared_examples 'a hook that gets automatically disabled on failure' do
  let(:logger) { instance_double('Gitlab::WebHooks::Logger') }

  before do
    allow(hook).to receive(:logger).and_return(logger)
    allow(logger).to receive(:info)
  end

  describe '.executable and .disabled', :freeze_time do
    include_context 'with webhook auto-disabling failure thresholds'

    with_them do
      let(:web_hook) do
        factory_arguments = default_factory_arguments.merge(
          recent_failures: recent_failures,
          disabled_until: disabled_until
        )

        create(hook_factory, **factory_arguments)
      end

      it 'scopes correctly' do
        if executable
          expect(find_hooks.executable).to match_array([web_hook])
          expect(find_hooks.disabled).to be_empty
        else
          expect(find_hooks.executable).to be_empty
          expect(find_hooks.disabled).to match_array([web_hook])
        end
      end

      context 'when the flag is disabled' do
        before do
          stub_feature_flags(auto_disabling_web_hooks: false)
        end

        it 'causes all hooks to be scoped as executable' do
          expect(find_hooks.executable).to match_array([web_hook])
          expect(find_hooks.disabled).to be_empty
        end
      end

      context 'when silent mode is enabled' do
        before do
          stub_application_setting(silent_mode_enabled: true)
        end

        it 'causes all hooks to be scoped as disabled' do
          expect(find_hooks.executable).to be_empty
          expect(find_hooks.disabled).to match_array([web_hook])
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

        create(hook_factory, **factory_arguments)
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

  describe '#enable!', :freeze_time do
    before do
      hook.recent_failures = WebHooks::AutoDisabling::TEMPORARILY_DISABLED_FAILURE_THRESHOLD
      hook.backoff!
    end

    it 'makes a hook executable' do
      expect { hook.enable! }.to change { hook.executable? }.from(false).to(true)
    end

    it 'logs relevant information' do
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
      hook.recent_failures = 0
      hook.backoff_count = 0
      hook.disabled_until = nil

      sql_count = ActiveRecord::QueryRecorder.new { hook.enable! }.count

      expect(sql_count).to eq(0)
    end

    it 'is tolerant of invalid records' do
      hook.url = nil

      expect(hook).to be_invalid
      expect { hook.enable! }.to change { hook.executable? }.from(false).to(true)
    end
  end

  describe '#backoff!' do
    around do |example|
      if example.metadata[:skip_freeze_time]
        example.run
      else
        freeze_time { example.run }
      end
    end

    context 'when we have not backed off before' do
      it 'does not disable the hook' do
        expect { hook.backoff! }.not_to change { hook.executable? }.from(true)
        expect(hook.class.executable).to include(hook)
      end

      it 'increments recent_failures' do
        expect { hook.backoff! }.to change { hook.recent_failures }.from(0).to(1)
      end

      it 'does not increment backoff_count' do
        expect { hook.backoff! }.not_to change { hook.backoff_count }.from(0)
      end

      it 'does not set disabled_until' do
        expect { hook.backoff! }.not_to change { hook.disabled_until }.from(nil)
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

    context 'when failures exceed the threshold' do
      before do
        hook.update!(recent_failures: WebHooks::AutoDisabling::TEMPORARILY_DISABLED_FAILURE_THRESHOLD)
      end

      it 'temporarily disables the hook' do
        expect { hook.backoff! }.to change { hook.executable? }.from(true).to(false)
        expect(hook).to be_temporarily_disabled
        expect(hook).not_to be_permanently_disabled
        expect(hook.class.executable).not_to include(hook)
      end

      it 'increments backoff_count' do
        expect { hook.backoff! }.to change { hook.backoff_count }.from(0).to(1)
      end

      it 'increments recent_failures' do
        expect { hook.backoff! }.to change {
          hook.recent_failures
        }.from(WebHooks::AutoDisabling::TEMPORARILY_DISABLED_FAILURE_THRESHOLD)
         .to(WebHooks::AutoDisabling::TEMPORARILY_DISABLED_FAILURE_THRESHOLD + 1)
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
            recent_failures: WebHooks::AutoDisabling::TEMPORARILY_DISABLED_FAILURE_THRESHOLD + 1,
            disabled_until: 1.minute.from_now,
            backoff_count: 1
          ))

        hook.backoff!
      end

      it 'is no longer disabled after the backoff time has elapsed', :skip_freeze_time do
        hook.backoff!

        expect(hook).to be_temporarily_disabled
        expect(hook).not_to be_permanently_disabled
        expect(hook.class.executable).not_to include(hook)

        travel_to(hook.disabled_until + 1.second) do
          expect(hook).not_to be_temporarily_disabled
          expect(hook).not_to be_permanently_disabled
          expect(hook.class.executable).to include(hook)
        end
      end

      it 'increases the backoff time exponentially', :skip_freeze_time do
        hook.backoff!

        expect(hook).to have_attributes(
          recent_failures: (WebHooks::AutoDisabling::TEMPORARILY_DISABLED_FAILURE_THRESHOLD + 1),
          backoff_count: 1,
          disabled_until: be_like_time(Time.zone.now + 1.minute)
        )

        travel_to(hook.disabled_until + 1.second) do
          hook.backoff!

          expect(hook).to have_attributes(
            recent_failures: (WebHooks::AutoDisabling::TEMPORARILY_DISABLED_FAILURE_THRESHOLD + 2),
            backoff_count: 2,
            disabled_until: be_like_time(Time.zone.now + 2.minutes)
          )
        end

        travel_to(hook.disabled_until + 1.second) do
          hook.backoff!

          expect(hook).to have_attributes(
            recent_failures: (WebHooks::AutoDisabling::TEMPORARILY_DISABLED_FAILURE_THRESHOLD + 3),
            backoff_count: 3,
            disabled_until: be_like_time(Time.zone.now + 4.minutes)
          )
        end
      end

      context 'when the hook is permanently disabled' do
        before do
          allow(hook).to receive(:permanently_disabled?).and_return(true)
        end

        it 'does not do anything' do
          sql_count = ActiveRecord::QueryRecorder.new { hook.backoff! }.count

          expect(sql_count).to eq(0)
        end
      end

      context 'when the hook is temporarily disabled' do
        before do
          allow(hook).to receive(:temporarily_disabled?).and_return(true)
        end

        it 'does not do anything' do
          sql_count = ActiveRecord::QueryRecorder.new { hook.backoff! }.count

          expect(sql_count).to eq(0)
        end
      end

      context 'when the flag is disabled' do
        before do
          stub_feature_flags(auto_disabling_web_hooks: false)
        end

        it 'does not disable the hook' do
          expect { hook.backoff! }.not_to change { hook.executable? }.from(true)
          expect(hook).not_to be_temporarily_disabled
          expect(hook).not_to be_permanently_disabled
          expect(hook.class.executable).to include(hook)
        end
      end

      it 'is tolerant of invalid records' do
        hook.url = nil

        expect(hook).to be_invalid
        expect { hook.backoff! }.to change { hook.backoff_count }.by(1)
      end
    end
  end

  describe '#temporarily_disabled? and #permanently_disabled?', :freeze_time do
    it 'is initially not disabled at all' do
      expect(hook).not_to be_temporarily_disabled
      expect(hook).not_to be_permanently_disabled
    end

    it 'becomes temporarily disabled after a threshold of failures has been exceeded' do
      WebHooks::AutoDisabling::TEMPORARILY_DISABLED_FAILURE_THRESHOLD.times do
        hook.backoff!

        expect(hook).not_to be_temporarily_disabled
        expect(hook).not_to be_permanently_disabled
      end

      hook.backoff!

      expect(hook).to be_temporarily_disabled
      expect(hook).not_to be_permanently_disabled
    end

    context 'when the flag is disabled' do
      before do
        stub_feature_flags(auto_disabling_web_hooks: false)
      end

      it 'is not disabled at all' do
        hook.update!(recent_failures: WebHooks::AutoDisabling::TEMPORARILY_DISABLED_FAILURE_THRESHOLD)
        hook.backoff!

        expect(hook).not_to be_temporarily_disabled
        expect(hook).not_to be_permanently_disabled
      end
    end

    context 'when hook exceeds the permanently disabled threshold' do
      before do
        hook.update!(recent_failures: WebHooks::AutoDisabling::PERMANENTLY_DISABLED_FAILURE_THRESHOLD)
        hook.backoff!
      end

      it 'is permanently disabled' do
        expect(hook).to be_permanently_disabled
        expect(hook).not_to be_temporarily_disabled
      end

      context 'when the flag is disabled' do
        before do
          stub_feature_flags(auto_disabling_web_hooks: false)
        end

        it 'is not disabled at all' do
          expect(hook).not_to be_temporarily_disabled
          expect(hook).not_to be_permanently_disabled
        end
      end
    end

    # TODO Remove as part of https://gitlab.com/gitlab-org/gitlab/-/issues/525446
    context 'when hook has no disabled_until set and exceeds TEMPORARILY_DISABLED_FAILURE_THRESHOLD (legacy state)' do
      before do
        hook.update!(recent_failures: WebHooks::AutoDisabling::TEMPORARILY_DISABLED_FAILURE_THRESHOLD + 1)
      end

      it 'is permanently disabled' do
        expect(hook).to be_permanently_disabled
        expect(hook).not_to be_temporarily_disabled
      end

      context 'when the flag is disabled' do
        before do
          stub_feature_flags(auto_disabling_web_hooks: false)
        end

        it 'is not disabled at all' do
          expect(hook).not_to be_permanently_disabled
          expect(hook).not_to be_temporarily_disabled
        end
      end
    end
  end

  describe '#alert_status' do
    subject(:status) { hook.alert_status }

    it { is_expected.to eq(:executable) }

    context 'when hook has been permanently disabled' do
      before do
        allow(hook).to receive(:permanently_disabled?).and_return(true)
      end

      it { is_expected.to eq(:disabled) }

      context 'when the flag is disabled' do
        before do
          stub_feature_flags(auto_disabling_web_hooks: false)
        end

        it { is_expected.to eq(:executable) }
      end
    end

    context 'when hook has been temporarily disabled' do
      before do
        allow(hook).to receive(:temporarily_disabled?).and_return(true)
      end

      it { is_expected.to eq(:temporarily_disabled) }

      context 'when the flag is disabled' do
        before do
          stub_feature_flags(auto_disabling_web_hooks: false)
        end

        it { is_expected.to eq(:executable) }
      end
    end
  end
end
