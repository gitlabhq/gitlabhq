# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::Stateful, feature_category: :organization do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:user) { create(:user) }
  let_it_be_with_reload(:organization) { create(:organization) }

  describe 'constants' do
    it 'defines DELETION_STATES' do
      expect(described_class::DELETION_STATES).to eq(%i[soft_deleted deletion_in_progress])
    end

    it 'defines MAINTENANCE_REASONS' do
      expect(described_class::MAINTENANCE_REASONS).to eq(%w[migration isolation incident billing legal])
    end

    it 'keeps MAINTENANCE_REASONS in sync with the state_metadata JSON schema' do
      schema = 'app/validators/json_schemas/organization_detail_state_metadata.json'
      schema_reasons = Gitlab::Json.safe_parse(File.read(schema)).dig('properties', 'maintenance_reason', 'enum')

      expect(schema_reasons).to match_array(described_class::MAINTENANCE_REASONS)
    end

    it 'defines TIME_BOUNDED_MAINTENANCE_REASONS as a subset of MAINTENANCE_REASONS' do
      expect(described_class::TIME_BOUNDED_MAINTENANCE_REASONS).to eq(%w[migration incident])
      expect(described_class::MAINTENANCE_REASONS).to include(*described_class::TIME_BOUNDED_MAINTENANCE_REASONS)
    end
  end

  describe 'enums' do
    subject { organization }

    it 'defines state enum with correct values' do
      is_expected.to define_enum_for(:state)
        .with_values(
          unconfirmed: 0,
          soft_deleted: 1,
          deletion_in_progress: 2,
          confirmed: 3,
          active: 4,
          maintenance_initialization: 5,
          maintenance: 6
        )
        .without_instance_methods
    end
  end

  describe 'state machine' do
    subject { organization }

    it 'declares all expected states' do
      is_expected.to have_states(
        :active, :soft_deleted, :deletion_in_progress, :unconfirmed, :confirmed,
        :maintenance_initialization, :maintenance
      )
    end

    it 'has unconfirmed as initial state for new records' do
      new_organization = Organizations::Organization.new(name: 'Test', path: 'test-org')
      expect(new_organization.state_name).to eq(:unconfirmed)
    end

    describe 'valid transitions' do
      it { is_expected.to handle_events :confirm, when: :unconfirmed }
      it { is_expected.to handle_events :activate, when: :confirmed }
      it { is_expected.to handle_events :soft_delete, when: :active }
      it { is_expected.to handle_events :hard_delete, when: :soft_deleted }
      it { is_expected.to handle_events :abort_hard_deletion, when: :deletion_in_progress }
      it { is_expected.to handle_events :restore, when: :soft_deleted }
      it { is_expected.to handle_events :start_maintenance, when: :active }
      it { is_expected.to handle_events :confirm_maintenance, when: :maintenance_initialization }
      it { is_expected.to handle_events :cancel_maintenance, when: :maintenance_initialization }
      it { is_expected.to handle_events :exit_maintenance, when: :maintenance }
    end

    describe 'rejected transitions' do
      where(:from_state, :event) do
        :unconfirmed              | :activate
        :unconfirmed              | :soft_delete
        :unconfirmed              | :hard_delete
        :unconfirmed              | :abort_hard_deletion
        :unconfirmed              | :restore
        :unconfirmed              | :start_maintenance
        :unconfirmed              | :confirm_maintenance
        :unconfirmed              | :cancel_maintenance
        :unconfirmed              | :exit_maintenance
        :confirmed                | :confirm
        :confirmed                | :soft_delete
        :confirmed                | :hard_delete
        :confirmed                | :abort_hard_deletion
        :confirmed                | :restore
        :confirmed                | :start_maintenance
        :confirmed                | :confirm_maintenance
        :confirmed                | :cancel_maintenance
        :confirmed                | :exit_maintenance
        :active                   | :confirm
        :active                   | :activate
        :active                   | :hard_delete
        :active                   | :abort_hard_deletion
        :active                   | :restore
        :active                   | :confirm_maintenance
        :active                   | :cancel_maintenance
        :active                   | :exit_maintenance
        :soft_deleted             | :soft_delete
        :soft_deleted             | :abort_hard_deletion
        :soft_deleted             | :start_maintenance
        :soft_deleted             | :confirm_maintenance
        :soft_deleted             | :cancel_maintenance
        :soft_deleted             | :exit_maintenance
        :deletion_in_progress     | :soft_delete
        :deletion_in_progress     | :hard_delete
        :deletion_in_progress     | :restore
        :deletion_in_progress     | :start_maintenance
        :deletion_in_progress     | :confirm_maintenance
        :deletion_in_progress     | :cancel_maintenance
        :deletion_in_progress     | :exit_maintenance
        :maintenance_initialization | :confirm
        :maintenance_initialization | :activate
        :maintenance_initialization | :soft_delete
        :maintenance_initialization | :hard_delete
        :maintenance_initialization | :abort_hard_deletion
        :maintenance_initialization | :restore
        :maintenance_initialization | :start_maintenance
        :maintenance_initialization | :exit_maintenance
        :maintenance                | :confirm
        :maintenance                | :activate
        :maintenance                | :soft_delete
        :maintenance                | :hard_delete
        :maintenance                | :abort_hard_deletion
        :maintenance                | :restore
        :maintenance                | :start_maintenance
        :maintenance                | :confirm_maintenance
        :maintenance                | :cancel_maintenance
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

    context 'with transition_user-requiring events' do
      where(:from_state, :event, :to_state) do
        :active               | :soft_delete         | :soft_deleted
        :soft_deleted         | :hard_delete         | :deletion_in_progress
        :deletion_in_progress | :abort_hard_deletion | :soft_deleted
        :soft_deleted         | :restore             | :active
      end

      with_them do
        before do
          organization.update_column(:state, Organizations::Organization.states[from_state])
        end

        it "prevents #{params[:event]} without a transition_user" do
          expect(organization.public_send(event)).to be false
          expect(organization.errors[:state])
            .to include("#{event} transition needs transition_user")
        end

        it "allows #{params[:event]} with a transition_user" do
          expect { organization.public_send(event, transition_user: user) }
            .to change { organization.state_name }
            .from(from_state)
            .to(to_state)
        end
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
      let_it_be_with_reload(:existing_org) { create(:organization) }

      it 'can be active with nil confirmed_by_user_id in state_metadata' do
        expect(existing_org.organization_detail.confirmed_by_user_id).to be_nil
        expect(existing_org).to be_active
      end

      it 'can be active with nil confirmed_at in state_metadata' do
        expect(existing_org.organization_detail.confirmed_at).to be_nil
        expect(existing_org).to be_active
      end

      it 'can soft delete without confirmed_by_user_id' do
        expect { existing_org.soft_delete(transition_user: user) }
          .to change { existing_org.state_name }
          .from(:active)
          .to(:soft_deleted)
      end
    end
  end

  describe '#ensure_organization_is_empty' do
    where(:from_state, :event, :to_state) do
      :active       | :soft_delete | :soft_deleted
      :soft_deleted | :hard_delete | :deletion_in_progress
    end

    with_them do
      before do
        organization.update_column(:state, Organizations::Organization.states[from_state])
      end

      it "prevents #{params[:event]} when organization is not empty" do
        create(:group, organization: organization)

        expect(organization.public_send(event, transition_user: user)).to be false
        expect(organization.errors[:state])
          .to include("#{event} transition requires the organization to be empty")
      end

      it "allows #{params[:event]} when organization is empty" do
        expect { organization.public_send(event, transition_user: user) }
          .to change { organization.state_name }
          .from(from_state)
          .to(to_state)
      end
    end
  end

  describe '#set_soft_deletion_data' do
    before do
      organization.update_column(:state, Organizations::Organization.states[:active])
    end

    it 'sets soft_deleted_at on the detail' do
      freeze_time do
        organization.soft_delete(transition_user: user)

        expect(organization.organization_detail.soft_deleted_at)
          .to be_within(1.minute).of(Time.current)
      end
    end

    it 'stores soft_deletion_scheduled_by_user_id in state_metadata' do
      organization.soft_delete(transition_user: user)
      organization.reload

      expect(organization.organization_detail.state_metadata['soft_deletion_scheduled_by_user_id'])
        .to eq(user.id)
    end
  end

  describe '#clear_soft_deletion_data' do
    before do
      organization.update_column(:state, Organizations::Organization.states[:active])
      organization.soft_delete(transition_user: user)
    end

    it 'clears soft_deleted_at' do
      organization.restore(transition_user: user)

      expect(organization.organization_detail.soft_deleted_at).to be_nil
    end

    it 'removes soft_deletion_scheduled_by_user_id from state_metadata' do
      organization.restore(transition_user: user)
      organization.reload

      expect(organization.organization_detail.state_metadata)
        .not_to have_key('soft_deletion_scheduled_by_user_id')
    end
  end

  describe '#update_state_metadata_on_failure' do
    it 'records error in state_metadata when transition is invalid' do
      organization.restore
      organization.reload

      expect(organization.organization_detail.state_metadata['last_error'])
        .to include('Cannot transition')
    end
  end

  # ---------------------------------------------------------------------------
  # Maintenance state machine
  # ---------------------------------------------------------------------------

  describe '#start_maintenance' do
    before do
      organization.update_column(:state, Organizations::Organization.states[:active])
    end

    it 'transitions from active to maintenance_initialization with a valid reason' do
      expect { organization.start_maintenance(maintenance_reason: 'migration') }
        .to change { organization.state_name }
        .from(:active)
        .to(:maintenance_initialization)
    end

    it 'persists the maintenance_reason in state_metadata' do
      organization.start_maintenance(maintenance_reason: 'billing')
      organization.reload

      expect(organization.organization_detail.state_metadata['maintenance_reason']).to eq('billing')
    end

    it 'accepts all valid reasons', :aggregate_failures do
      described_class::MAINTENANCE_REASONS.each do |reason|
        org = create(:organization)
        expect(org.start_maintenance(maintenance_reason: reason)).to be_truthy
        expect(org.state_name).to eq(:maintenance_initialization)
      end
    end

    it 'rejects an invalid reason', :aggregate_failures do
      expect(organization.start_maintenance(maintenance_reason: 'unknown')).to be false
      expect(organization.errors[:state]).to include(
        a_string_matching(/requires a valid maintenance_reason/)
      )
    end

    it 'rejects a nil reason', :aggregate_failures do
      expect(organization.start_maintenance).to be false
      expect(organization.errors[:state]).to include(
        a_string_matching(/requires a valid maintenance_reason/)
      )
    end

    it 'does not change state when reason is invalid' do
      organization.start_maintenance(maintenance_reason: 'bad')

      expect(organization.state_name).to eq(:active)
    end
  end

  describe '#confirm_maintenance' do
    before do
      organization.update_column(:state, Organizations::Organization.states[:maintenance_initialization])
    end

    it 'transitions from maintenance_initialization to maintenance' do
      expect { organization.confirm_maintenance }
        .to change { organization.state_name }
        .from(:maintenance_initialization)
        .to(:maintenance)
    end
  end

  describe '#cancel_maintenance' do
    before do
      organization.update_column(:state, Organizations::Organization.states[:maintenance_initialization])
      organization.organization_detail.update!(state_metadata: { 'maintenance_reason' => 'incident' })
    end

    it 'transitions from maintenance_initialization back to active' do
      expect { organization.cancel_maintenance }
        .to change { organization.state_name }
        .from(:maintenance_initialization)
        .to(:active)
    end

    it 'clears maintenance_reason from state_metadata' do
      organization.cancel_maintenance
      organization.reload

      expect(organization.organization_detail.state_metadata).not_to have_key('maintenance_reason')
    end
  end

  describe '#exit_maintenance' do
    before do
      organization.update_column(:state, Organizations::Organization.states[:maintenance])
      organization.organization_detail.update!(state_metadata: { 'maintenance_reason' => 'legal' })
    end

    it 'transitions from maintenance back to active' do
      expect { organization.exit_maintenance }
        .to change { organization.state_name }
        .from(:maintenance)
        .to(:active)
    end

    it 'clears maintenance_reason from state_metadata' do
      organization.exit_maintenance
      organization.reload

      expect(organization.organization_detail.state_metadata).not_to have_key('maintenance_reason')
    end
  end

  describe '#maintenance_time_bounded?' do
    subject(:maintenance_time_bounded?) { organization.maintenance_time_bounded? }

    where(:reason, :expected) do
      'migration' | true
      'incident'  | true
      'isolation' | false
      'billing'   | false
      'legal'     | false
      nil         | false
    end

    with_them do
      before do
        organization.maintenance_reason = reason
      end

      it { is_expected.to eq(expected) }
    end
  end

  describe '#maintenance_message' do
    subject(:maintenance_message) { organization.maintenance_message }

    context 'when the maintenance reason is time-bounded' do
      before do
        organization.maintenance_reason = 'migration'
      end

      it { is_expected.to eq('This organization is temporarily unavailable due to maintenance.') }
    end

    context 'when the maintenance reason is indefinite' do
      before do
        organization.maintenance_reason = 'legal'
      end

      it { is_expected.to eq('This organization is unavailable.') }
    end
  end

  describe 'guard: default organization cannot enter maintenance' do
    # rubocop:disable Gitlab/RSpec/AvoidCreateDefaultOrganization -- required for testing default organization guard
    let_it_be_with_reload(:default_org) { create(:organization, :default) }
    # rubocop:enable Gitlab/RSpec/AvoidCreateDefaultOrganization

    where(:event) do
      [:start_maintenance]
    end

    with_them do
      before do
        default_org.update_column(:state, Organizations::Organization.states[:active])
      end

      it "rejects #{params[:event]} for the default organization", :aggregate_failures do
        expect(default_org.public_send(event, maintenance_reason: 'migration')).to be false
        expect(default_org.errors[:state]).to include(
          a_string_matching(/not allowed for the default organization/)
        )
      end

      it 'does not change the state of the default organization' do
        default_org.public_send(event, maintenance_reason: 'migration')

        expect(default_org.state_name).to eq(:active)
      end
    end

    it 'also rejects confirm_maintenance for the default organization', :aggregate_failures do
      default_org.update_column(:state, Organizations::Organization.states[:maintenance_initialization])

      expect(default_org.confirm_maintenance).to be false
      expect(default_org.errors[:state]).to include(
        a_string_matching(/not allowed for the default organization/)
      )
    end
  end

  describe 'blocked states cannot enter maintenance' do
    where(:from_state) do
      %i[soft_deleted deletion_in_progress unconfirmed confirmed].map { |s| [s] }
    end

    with_them do
      before do
        organization.update_column(:state, Organizations::Organization.states[from_state])
      end

      it "rejects start_maintenance from #{params[:from_state]}", :aggregate_failures do
        expect(organization.start_maintenance(maintenance_reason: 'migration')).to be false
        expect(organization.state_name).to eq(from_state)
      end

      it "rejects confirm_maintenance from #{params[:from_state]}", :aggregate_failures do
        expect(organization.confirm_maintenance).to be false
        expect(organization.state_name).to eq(from_state)
      end
    end
  end

  describe 'transition logging' do
    it 'calls log_transition after a successful maintenance transition' do
      organization.update_column(:state, Organizations::Organization.states[:active])

      expect(Gitlab::AppLogger).to receive(:info).with(
        hash_including(
          message: 'Organization state transition',
          organization_id: organization.id,
          from_state: :active,
          to_state: :maintenance_initialization,
          event: :start_maintenance
        )
      )

      organization.start_maintenance(maintenance_reason: 'isolation')
    end

    it 'calls log_transition after confirm_maintenance' do
      organization.update_column(:state, Organizations::Organization.states[:maintenance_initialization])

      expect(Gitlab::AppLogger).to receive(:info).with(
        hash_including(
          from_state: :maintenance_initialization,
          to_state: :maintenance,
          event: :confirm_maintenance
        )
      )

      organization.confirm_maintenance
    end

    it 'calls log_transition after cancel_maintenance' do
      organization.update_column(:state, Organizations::Organization.states[:maintenance_initialization])

      expect(Gitlab::AppLogger).to receive(:info).with(
        hash_including(
          from_state: :maintenance_initialization,
          to_state: :active,
          event: :cancel_maintenance
        )
      )

      organization.cancel_maintenance
    end

    it 'calls log_transition after exit_maintenance' do
      organization.update_column(:state, Organizations::Organization.states[:maintenance])

      expect(Gitlab::AppLogger).to receive(:info).with(
        hash_including(
          from_state: :maintenance,
          to_state: :active,
          event: :exit_maintenance
        )
      )

      organization.exit_maintenance
    end
  end
end
