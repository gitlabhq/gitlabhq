# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::Stateful, feature_category: :organization do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:user) { create(:user) }
  let_it_be_with_reload(:organization) { create(:organization) }

  describe 'enums' do
    subject { organization }

    it 'defines state enum with correct values' do
      is_expected.to define_enum_for(:state)
        .with_values(unconfirmed: 0, deletion_scheduled: 1, deletion_in_progress: 2, confirmed: 3, active: 4)
        .without_instance_methods
    end
  end

  describe 'state machine' do
    subject { organization }

    it 'declares all expected states' do
      is_expected.to have_states :active, :deletion_scheduled, :deletion_in_progress, :unconfirmed, :confirmed
    end

    it 'has unconfirmed as initial state for new records' do
      new_organization = Organizations::Organization.new(name: 'Test', path: 'test-org')
      expect(new_organization.state_name).to eq(:unconfirmed)
    end

    describe 'valid transitions' do
      it { is_expected.to handle_events :confirm, when: :unconfirmed }
      it { is_expected.to handle_events :activate, when: :confirmed }
      it { is_expected.to handle_events :schedule_deletion, when: :active }
      it { is_expected.to handle_events :start_deletion, when: :deletion_scheduled }
      it { is_expected.to handle_events :cancel_deletion, when: :deletion_scheduled }
      it { is_expected.to handle_events :cancel_deletion, when: :deletion_in_progress }
      it { is_expected.to handle_events :reschedule_deletion, when: :deletion_in_progress }
    end

    describe 'rejected transitions' do
      where(:from_state, :event) do
        :unconfirmed          | :activate
        :unconfirmed          | :schedule_deletion
        :unconfirmed          | :start_deletion
        :unconfirmed          | :cancel_deletion
        :unconfirmed          | :reschedule_deletion
        :confirmed            | :confirm
        :confirmed            | :schedule_deletion
        :confirmed            | :start_deletion
        :confirmed            | :cancel_deletion
        :confirmed            | :reschedule_deletion
        :active               | :confirm
        :active               | :activate
        :active               | :start_deletion
        :active               | :cancel_deletion
        :active               | :reschedule_deletion
        :deletion_scheduled   | :schedule_deletion
        :deletion_scheduled   | :reschedule_deletion
        :deletion_in_progress | :schedule_deletion
        :deletion_in_progress | :start_deletion
      end

      with_them do
        before do
          organization.update_column(:state, Organizations::Organization.states[from_state])
        end

        it "rejects #{params[:event]} from #{params[:from_state]}" do
          expect(organization.public_send(event)).to be false
        end
      end
    end
  end

  describe '#ensure_confirmed_by_user' do
    before do
      organization.update_column(:state, Organizations::Organization.states[:unconfirmed])
    end

    it 'prevents confirm without a confirmed_by_user' do
      expect(organization.confirm).to be false
      expect(organization.errors[:state])
        .to include('confirm transition needs confirmed_by_user')
    end

    it 'does not set confirmation data when confirmed_by_user is missing' do
      organization.confirm
      organization.reload

      expect(organization.organization_detail.confirmed_by_user_id).to be_nil
      expect(organization.organization_detail.confirmed_at).to be_nil
    end

    it 'allows confirm with a confirmed_by_user' do
      expect { organization.confirm(confirmed_by_user: user) }
        .to change { organization.state_name }
        .from(:unconfirmed)
        .to(:confirmed)
    end

    context 'with schedule_deletion' do
      before do
        organization.update_column(:state, Organizations::Organization.states[:active])
      end

      it 'prevents schedule_deletion without a transition_user' do
        expect(organization.schedule_deletion).to be false
        expect(organization.errors[:state])
          .to include('schedule_deletion transition needs transition_user')
      end

      it 'allows schedule_deletion with a transition_user' do
        expect { organization.schedule_deletion(transition_user: user) }
          .to change { organization.state_name }
          .from(:active)
          .to(:deletion_scheduled)
      end
    end
  end

  describe '#activate' do
    before do
      organization.update_column(:state, Organizations::Organization.states[:confirmed])
    end

    it 'transitions from confirmed to active' do
      expect { organization.activate }
        .to change { organization.state_name }
        .from(:confirmed)
        .to(:active)
    end
  end

  describe '#set_confirmation_data' do
    before do
      organization.update_column(:state, Organizations::Organization.states[:unconfirmed])
    end

    it 'sets confirmed_at in state_metadata' do
      freeze_time do
        organization.confirm(confirmed_by_user: user)
        organization.reload

        expect(organization.organization_detail.state_metadata['confirmed_at'])
          .to eq(Time.current.as_json)
      end
    end

    it 'stores confirmed_by_user_id in state_metadata' do
      organization.confirm(confirmed_by_user: user)
      organization.reload

      expect(organization.organization_detail.state_metadata['confirmed_by_user_id'])
        .to eq(user.id)
    end
  end

  describe 'existing organizations with nil confirmation data' do
    context 'when an organization is active without confirmed_by_user_id or confirmed_at' do
      let_it_be(:existing_org) { create(:organization) }

      it 'can be active with nil confirmed_by_user_id in state_metadata' do
        expect(existing_org.organization_detail.confirmed_by_user_id).to be_nil
        expect(existing_org).to be_active
      end

      it 'can be active with nil confirmed_at in state_metadata' do
        expect(existing_org.organization_detail.confirmed_at).to be_nil
        expect(existing_org).to be_active
      end

      it 'can schedule deletion without confirmed_by_user_id' do
        expect { existing_org.schedule_deletion(transition_user: user) }
          .to change { existing_org.state_name }
          .from(:active)
          .to(:deletion_scheduled)
      end
    end
  end

  describe '#ensure_organization_is_empty' do
    it 'prevents schedule_deletion when organization is not empty' do
      create(:group, organization: organization)

      expect(organization.schedule_deletion(transition_user: user)).to be false
      expect(organization.errors[:state])
        .to include('schedule_deletion transition requires the organization to be empty')
    end

    it 'allows schedule_deletion when organization is empty' do
      expect { organization.schedule_deletion(transition_user: user) }
        .to change { organization.state_name }
        .from(:active)
        .to(:deletion_scheduled)
    end
  end

  describe '#set_deletion_schedule_data' do
    before do
      organization.update_column(:state, Organizations::Organization.states[:active])
    end

    it 'sets deletion_scheduled_at on the detail' do
      freeze_time do
        organization.schedule_deletion(transition_user: user)

        expect(organization.organization_detail.deletion_scheduled_at)
          .to be_within(1.minute).of(Time.current)
      end
    end

    it 'stores deletion_scheduled_by_user_id in state_metadata' do
      organization.schedule_deletion(transition_user: user)
      organization.reload

      expect(organization.organization_detail.state_metadata['deletion_scheduled_by_user_id'])
        .to eq(user.id)
    end
  end

  describe '#clear_deletion_schedule_data' do
    before do
      organization.update_column(:state, Organizations::Organization.states[:active])
      organization.schedule_deletion(transition_user: user)
    end

    it 'clears deletion_scheduled_at' do
      organization.cancel_deletion

      expect(organization.organization_detail.deletion_scheduled_at).to be_nil
    end

    it 'removes deletion_scheduled_by_user_id from state_metadata' do
      organization.cancel_deletion
      organization.reload

      expect(organization.organization_detail.state_metadata)
        .not_to have_key('deletion_scheduled_by_user_id')
    end
  end

  describe '#update_state_metadata_on_failure' do
    it 'records error in state_metadata when transition is invalid' do
      organization.cancel_deletion
      organization.reload

      expect(organization.organization_detail.state_metadata['last_error'])
        .to include('Cannot transition')
    end
  end
end
