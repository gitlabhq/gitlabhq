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

    it 'defines READ_ONLY_STATES' do
      expect(described_class::READ_ONLY_STATES).to eq(%i[read_only_initialization read_only])
    end

    it 'defines READ_ONLY_REASONS' do
      expect(described_class::READ_ONLY_REASONS).to eq(%w[migration isolation incident billing legal])
    end

    it 'keeps READ_ONLY_REASONS in sync with the state_metadata JSON schema' do
      schema = 'app/validators/json_schemas/organization_detail_state_metadata.json'
      schema_reasons = Gitlab::Json.safe_parse(File.read(schema)).dig('properties', 'read_only_reason', 'enum')

      expect(schema_reasons).to match_array(described_class::READ_ONLY_REASONS)
    end

    it 'defines READ_ONLY_BLOCKED_STATES' do
      expect(described_class::READ_ONLY_BLOCKED_STATES)
        .to contain_exactly(:soft_deleted, :deletion_in_progress, :unconfirmed, :confirmed)
    end

    it 'defines TIME_BOUNDED_READ_ONLY_REASONS as a subset of READ_ONLY_REASONS' do
      expect(described_class::TIME_BOUNDED_READ_ONLY_REASONS).to eq(%w[migration incident])
      expect(described_class::READ_ONLY_REASONS).to include(*described_class::TIME_BOUNDED_READ_ONLY_REASONS)
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
          read_only_initialization: 5,
          read_only: 6
        )
        .without_instance_methods
    end
  end

  describe 'scopes' do
    describe '.in_read_only_states' do
      let_it_be(:read_only_initialization_org) do
        create(:organization).tap { |o| o.update_column(:state, Organizations::Organization.states[:read_only_initialization]) }
      end

      let_it_be(:read_only_org) do
        create(:organization).tap { |o| o.update_column(:state, Organizations::Organization.states[:read_only]) }
      end

      let_it_be(:active_org) do
        create(:organization).tap { |o| o.update_column(:state, Organizations::Organization.states[:active]) }
      end

      it 'returns only organizations in read-only states' do
        expect(Organizations::Organization.in_read_only_states)
          .to contain_exactly(read_only_initialization_org, read_only_org)
      end
    end
  end

  describe 'state machine' do
    subject { organization }

    it 'declares all expected states' do
      is_expected.to have_states(
        :active, :soft_deleted, :deletion_in_progress, :unconfirmed, :confirmed,
        :read_only_initialization, :read_only
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
      it { is_expected.to handle_events :start_read_only, when: :active }
      it { is_expected.to handle_events :confirm_read_only, when: :read_only_initialization }
      it { is_expected.to handle_events :cancel_read_only, when: :read_only_initialization }
      it { is_expected.to handle_events :exit_read_only, when: :read_only }
    end

    describe 'rejected transitions' do
      where(:from_state, :event) do
        :unconfirmed              | :activate
        :unconfirmed              | :soft_delete
        :unconfirmed              | :hard_delete
        :unconfirmed              | :abort_hard_deletion
        :unconfirmed              | :restore
        :unconfirmed              | :start_read_only
        :unconfirmed              | :confirm_read_only
        :unconfirmed              | :cancel_read_only
        :unconfirmed              | :exit_read_only
        :confirmed                | :confirm
        :confirmed                | :soft_delete
        :confirmed                | :hard_delete
        :confirmed                | :abort_hard_deletion
        :confirmed                | :restore
        :confirmed                | :start_read_only
        :confirmed                | :confirm_read_only
        :confirmed                | :cancel_read_only
        :confirmed                | :exit_read_only
        :active                   | :confirm
        :active                   | :activate
        :active                   | :hard_delete
        :active                   | :abort_hard_deletion
        :active                   | :restore
        :active                   | :confirm_read_only
        :active                   | :cancel_read_only
        :active                   | :exit_read_only
        :soft_deleted             | :soft_delete
        :soft_deleted             | :abort_hard_deletion
        :soft_deleted             | :start_read_only
        :soft_deleted             | :confirm_read_only
        :soft_deleted             | :cancel_read_only
        :soft_deleted             | :exit_read_only
        :deletion_in_progress     | :soft_delete
        :deletion_in_progress     | :hard_delete
        :deletion_in_progress     | :restore
        :deletion_in_progress     | :start_read_only
        :deletion_in_progress     | :confirm_read_only
        :deletion_in_progress     | :cancel_read_only
        :deletion_in_progress     | :exit_read_only
        :read_only_initialization | :confirm
        :read_only_initialization | :activate
        :read_only_initialization | :soft_delete
        :read_only_initialization | :hard_delete
        :read_only_initialization | :abort_hard_deletion
        :read_only_initialization | :restore
        :read_only_initialization | :start_read_only
        :read_only_initialization | :exit_read_only
        :read_only                | :confirm
        :read_only                | :activate
        :read_only                | :soft_delete
        :read_only                | :hard_delete
        :read_only                | :abort_hard_deletion
        :read_only                | :restore
        :read_only                | :start_read_only
        :read_only                | :confirm_read_only
        :read_only                | :cancel_read_only
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
  # Read-only state machine
  # ---------------------------------------------------------------------------

  describe '#start_read_only' do
    before do
      organization.update_column(:state, Organizations::Organization.states[:active])
    end

    it 'transitions from active to read_only_initialization with a valid reason' do
      expect { organization.start_read_only(read_only_reason: 'migration') }
        .to change { organization.state_name }
        .from(:active)
        .to(:read_only_initialization)
    end

    it 'persists the read_only_reason in state_metadata' do
      organization.start_read_only(read_only_reason: 'billing')
      organization.reload

      expect(organization.organization_detail.state_metadata['read_only_reason']).to eq('billing')
    end

    it 'accepts all valid reasons', :aggregate_failures do
      described_class::READ_ONLY_REASONS.each do |reason|
        org = create(:organization)
        expect(org.start_read_only(read_only_reason: reason)).to be_truthy
        expect(org.state_name).to eq(:read_only_initialization)
      end
    end

    it 'rejects an invalid reason', :aggregate_failures do
      expect(organization.start_read_only(read_only_reason: 'unknown')).to be false
      expect(organization.errors[:state]).to include(
        a_string_matching(/requires a valid read_only_reason/)
      )
    end

    it 'rejects a nil reason', :aggregate_failures do
      expect(organization.start_read_only).to be false
      expect(organization.errors[:state]).to include(
        a_string_matching(/requires a valid read_only_reason/)
      )
    end

    it 'does not change state when reason is invalid' do
      organization.start_read_only(read_only_reason: 'bad')

      expect(organization.state_name).to eq(:active)
    end
  end

  describe '#confirm_read_only' do
    before do
      organization.update_column(:state, Organizations::Organization.states[:read_only_initialization])
    end

    it 'transitions from read_only_initialization to read_only' do
      expect { organization.confirm_read_only }
        .to change { organization.state_name }
        .from(:read_only_initialization)
        .to(:read_only)
    end
  end

  describe '#cancel_read_only' do
    before do
      organization.update_column(:state, Organizations::Organization.states[:read_only_initialization])
      organization.organization_detail.update!(state_metadata: { 'read_only_reason' => 'incident' })
    end

    it 'transitions from read_only_initialization back to active' do
      expect { organization.cancel_read_only }
        .to change { organization.state_name }
        .from(:read_only_initialization)
        .to(:active)
    end

    it 'clears read_only_reason from state_metadata' do
      organization.cancel_read_only
      organization.reload

      expect(organization.organization_detail.state_metadata).not_to have_key('read_only_reason')
    end
  end

  describe '#exit_read_only' do
    before do
      organization.update_column(:state, Organizations::Organization.states[:read_only])
      organization.organization_detail.update!(state_metadata: { 'read_only_reason' => 'legal' })
    end

    it 'transitions from read_only back to active' do
      expect { organization.exit_read_only }
        .to change { organization.state_name }
        .from(:read_only)
        .to(:active)
    end

    it 'clears read_only_reason from state_metadata' do
      organization.exit_read_only
      organization.reload

      expect(organization.organization_detail.state_metadata).not_to have_key('read_only_reason')
    end
  end

  describe '#read_only?' do
    subject(:read_only?) { organization.read_only? }

    context 'when state is active' do
      before do
        organization.update_column(:state, Organizations::Organization.states[:active])
      end

      it { is_expected.to be false }
    end

    context 'when state is unconfirmed' do
      before do
        organization.update_column(:state, Organizations::Organization.states[:unconfirmed])
      end

      it { is_expected.to be false }
    end

    context 'when state is confirmed' do
      before do
        organization.update_column(:state, Organizations::Organization.states[:confirmed])
      end

      it { is_expected.to be false }
    end

    context 'when state is soft_deleted' do
      before do
        organization.update_column(:state, Organizations::Organization.states[:soft_deleted])
      end

      it { is_expected.to be false }
    end

    context 'when state is deletion_in_progress' do
      before do
        organization.update_column(:state, Organizations::Organization.states[:deletion_in_progress])
      end

      it { is_expected.to be false }
    end

    context 'when state is read_only_initialization' do
      before do
        organization.update_column(:state, Organizations::Organization.states[:read_only_initialization])
      end

      it { is_expected.to be true }
    end

    context 'when state is read_only' do
      before do
        organization.update_column(:state, Organizations::Organization.states[:read_only])
      end

      it { is_expected.to be true }
    end
  end

  describe '#read_only_time_bounded?' do
    subject(:read_only_time_bounded?) { organization.read_only_time_bounded? }

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
        organization.read_only_reason = reason
      end

      it { is_expected.to eq(expected) }
    end
  end

  describe 'guard: default organization cannot enter read-only' do
    # rubocop:disable Gitlab/RSpec/AvoidCreateDefaultOrganization -- required for testing default organization guard
    let_it_be_with_reload(:default_org) { create(:organization, :default) }
    # rubocop:enable Gitlab/RSpec/AvoidCreateDefaultOrganization

    where(:event) do
      [:start_read_only]
    end

    with_them do
      before do
        default_org.update_column(:state, Organizations::Organization.states[:active])
      end

      it "rejects #{params[:event]} for the default organization", :aggregate_failures do
        expect(default_org.public_send(event, read_only_reason: 'migration')).to be false
        expect(default_org.errors[:state]).to include(
          a_string_matching(/not allowed for the default organization/)
        )
      end

      it 'does not change the state of the default organization' do
        default_org.public_send(event, read_only_reason: 'migration')

        expect(default_org.state_name).to eq(:active)
      end
    end

    it 'also rejects confirm_read_only for the default organization', :aggregate_failures do
      default_org.update_column(:state, Organizations::Organization.states[:read_only_initialization])

      expect(default_org.confirm_read_only).to be false
      expect(default_org.errors[:state]).to include(
        a_string_matching(/not allowed for the default organization/)
      )
    end
  end

  describe 'blocked states cannot enter read-only' do
    where(:from_state) do
      described_class::READ_ONLY_BLOCKED_STATES.map { |s| [s] }
    end

    with_them do
      before do
        organization.update_column(:state, Organizations::Organization.states[from_state])
      end

      it "rejects start_read_only from #{params[:from_state]}", :aggregate_failures do
        expect(organization.start_read_only(read_only_reason: 'migration')).to be false
        expect(organization.state_name).to eq(from_state)
      end

      it "rejects confirm_read_only from #{params[:from_state]}", :aggregate_failures do
        expect(organization.confirm_read_only).to be false
        expect(organization.state_name).to eq(from_state)
      end
    end
  end

  describe 'transition logging' do
    it 'calls log_transition after a successful read-only transition' do
      organization.update_column(:state, Organizations::Organization.states[:active])

      expect(Gitlab::AppLogger).to receive(:info).with(
        hash_including(
          message: 'Organization state transition',
          organization_id: organization.id,
          from_state: :active,
          to_state: :read_only_initialization,
          event: :start_read_only
        )
      )

      organization.start_read_only(read_only_reason: 'isolation')
    end

    it 'calls log_transition after confirm_read_only' do
      organization.update_column(:state, Organizations::Organization.states[:read_only_initialization])

      expect(Gitlab::AppLogger).to receive(:info).with(
        hash_including(
          from_state: :read_only_initialization,
          to_state: :read_only,
          event: :confirm_read_only
        )
      )

      organization.confirm_read_only
    end

    it 'calls log_transition after cancel_read_only' do
      organization.update_column(:state, Organizations::Organization.states[:read_only_initialization])

      expect(Gitlab::AppLogger).to receive(:info).with(
        hash_including(
          from_state: :read_only_initialization,
          to_state: :active,
          event: :cancel_read_only
        )
      )

      organization.cancel_read_only
    end

    it 'calls log_transition after exit_read_only' do
      organization.update_column(:state, Organizations::Organization.states[:read_only])

      expect(Gitlab::AppLogger).to receive(:info).with(
        hash_including(
          from_state: :read_only,
          to_state: :active,
          event: :exit_read_only
        )
      )

      organization.exit_read_only
    end
  end
end
