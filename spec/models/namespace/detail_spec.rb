# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespace::Detail, type: :model, feature_category: :groups_and_projects do
  describe 'associations' do
    it { is_expected.to belong_to :namespace }
    it { is_expected.to belong_to(:creator).class_name('User') }

    it 'belongs to deletion_scheduled_by_user' do
      user = create(:user)
      namespace = create(:namespace, state_metadata: { 'deletion_scheduled_by_user_id' => user.id })

      expect(namespace.namespace_details.deletion_scheduled_by_user).to eq(user)
    end
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:namespace) }
    it { is_expected.to validate_length_of(:description).is_at_most(2000) }

    describe 'state_metadata' do
      let(:namespace_detail) { create(:namespace).namespace_details }

      it 'validates json_schema when state_metadata changes' do
        namespace_detail.state_metadata = { invalid_key: 'value' }

        expect(namespace_detail).not_to be_valid
        expect(namespace_detail.errors[:state_metadata]).to be_present
      end

      it 'does not validate json_schema when state_metadata is unchanged' do
        # Simulate invalid data already in the database
        namespace_detail.update_column(:state_metadata, { invalid_key: 'value' })
        namespace_detail.reload

        # Update a different attribute
        namespace_detail.description = 'New description'

        expect(namespace_detail).to be_valid
      end

      it 'accepts valid transfer fields in state_metadata' do
        namespace_detail.state_metadata = {
          transfer_initiated_at: Time.current.as_json,
          transfer_initiated_by_user_id: 1,
          transfer_target_parent_id: 2,
          transfer_attempt_count: 0,
          transfer_last_error: nil
        }

        expect(namespace_detail).to be_valid
      end

      it 'accepts schedule_transfer in preserved_states' do
        namespace_detail.state_metadata = {
          preserved_states: { schedule_transfer: 'archived' }
        }

        expect(namespace_detail).to be_valid
      end

      it 'rejects invalid transfer field values' do
        namespace_detail.state_metadata = {
          transfer_initiated_at: 'not-a-date'
        }

        expect(namespace_detail).not_to be_valid
        expect(namespace_detail.errors[:state_metadata]).to be_present
      end
    end
  end

  describe 'jsonb_accessor for transfer fields' do
    let(:namespace_detail) { create(:namespace).namespace_details }

    it 'provides accessors for transfer fields' do
      freeze_time do
        namespace_detail.update!(
          state_metadata: {
            transfer_initiated_at: Time.current.as_json,
            transfer_initiated_by_user_id: 42,
            transfer_target_parent_id: 99,
            transfer_attempt_count: 3,
            transfer_last_error: 'some error'
          }
        )
        namespace_detail.reload

        expect(namespace_detail.transfer_initiated_at).to eq(Time.current)
        expect(namespace_detail.transfer_initiated_by_user_id).to eq(42)
        expect(namespace_detail.transfer_target_parent_id).to eq(99)
        expect(namespace_detail.transfer_attempt_count).to eq(3)
        expect(namespace_detail.transfer_last_error).to eq('some error')
      end
    end
  end

  describe 'scopes' do
    describe '.deletion_scheduled_before' do
      let_it_be(:cutoff_time) { 10.days.ago.beginning_of_minute }

      let_it_be(:scheduled_before) do
        create(:namespace, deletion_scheduled_at: cutoff_time - 2.days).namespace_details
      end

      let_it_be(:scheduled_on_cutoff) do
        create(:namespace, deletion_scheduled_at: cutoff_time).namespace_details
      end

      let_it_be(:scheduled_after) do
        create(:namespace, deletion_scheduled_at: cutoff_time + 2.days).namespace_details
      end

      let_it_be(:not_scheduled) do
        create(:namespace).namespace_details
      end

      it 'returns details with deletion_scheduled_at on or before the specified time' do
        result = described_class.deletion_scheduled_before(cutoff_time)

        expect(result).to include(scheduled_before, scheduled_on_cutoff)
        expect(result).not_to include(scheduled_after, not_scheduled)
      end
    end
  end

  context 'with loose foreign key on namespace_details.creator_id' do
    it_behaves_like 'cleanup by a loose foreign key' do
      let_it_be(:parent) { create(:user) }
      let_it_be(:model) do
        namespace = create(:namespace, creator: parent)
        namespace.namespace_details
      end
    end
  end

  describe '#description_html' do
    let_it_be(:namespace_details) { create(:namespace, description: '### Foo **Bar**').namespace_details }
    let(:expected_description) { ' Foo <strong>Bar</strong> ' }

    subject { namespace_details.description_html }

    it { is_expected.to eq_no_sourcepos(expected_description) }
  end
end
