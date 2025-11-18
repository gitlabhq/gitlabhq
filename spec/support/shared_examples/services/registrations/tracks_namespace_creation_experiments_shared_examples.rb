# frozen_string_literal: true

RSpec.shared_examples 'tracks namespace creation experiments' do
  context 'with experiments' do
    it 'adds nav experiment context and tracks group', :experiment do
      stub_saas_features(onboarding: true)
      stub_experiments(default_pinned_nav_items: :candidate)

      user.user_detail.update!(onboarding_status: {
        registration_type: 'trial',
        role: 0, # software_developer
        registration_objective: 1 # move_repository
      })

      expect_any_instance_of(DefaultPinnedNavItemsExperiment) do |instance|
        expect(instance).to receive(:track).with(:assignment, namespace: anything).and_call_original
      end

      execute

      user.reload
      expect(user.onboarding_status[:experiments]).to include('default_pinned_nav_items')
    end

    context 'with experiment premium_trial_positioning', :experiment do
      before do
        stub_experiments(premium_trial_positioning: :control)
        allow_next_instance_of(::Projects::CreateService) do |service|
          allow(service).to receive(:after_create_actions)
        end
      end

      it 'uses onboarding user status to determine experiment exclusion' do
        onboarding_user_status = instance_double(::Onboarding::UserStatus)
        allow(::Onboarding::UserStatus).to receive(:new).with(user).and_return(onboarding_user_status)
        allow(onboarding_user_status).to receive_messages(
          exclude_from_first_orders_experiments?: true,
          apply_trial?: false
        )

        expect_any_instance_of(PremiumTrialPositioningExperiment) do |instance|
          expect(instance).to receive(:exclude!)
          expect(instance).to receive(:track).with(:assignment, namespace: an_instance_of(Group))
        end

        expect(execute).to be_success
      end
    end

    context 'with experiment lightweight_trial_registration_redesign' do
      let(:experiment) { instance_double(ApplicationExperiment) }

      it 'tracks experiment assignment' do
        allow_next_instance_of(::Projects::CreateService) do |service|
          allow(service).to receive(:after_create_actions)
        end

        expect_next_instance_of(described_class) do |service|
          expect(service).to receive(:experiment).with(:lightweight_trial_registration_redesign,
            actor: user).and_return(experiment)
          expect(service).to receive(:experiment).with(:premium_trial_positioning,
            actor: user).and_call_original
          expect(service).to receive(:experiment).with(:premium_message_during_trial,
            namespace: an_instance_of(Group)).and_call_original
        end

        expect(experiment).to receive(:track).with(:assignment, namespace: an_instance_of(Group))
        expect(execute).to be_success
      end
    end
  end
end
