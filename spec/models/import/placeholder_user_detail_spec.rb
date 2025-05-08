# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::PlaceholderUserDetail, type: :model, feature_category: :importers do
  describe 'associations' do
    it 'belong to placeholder_user' do
      is_expected.to belong_to(:placeholder_user).class_name('User').inverse_of(:placeholder_user_detail)
    end

    it 'belong to namespace' do
      is_expected.to belong_to(:namespace)
    end

    it 'belong to organization' do
      is_expected.to belong_to(:organization).class_name('Organizations::Organization')
    end
  end

  describe 'validations' do
    it { is_expected.to validate_numericality_of(:deletion_attempts).is_greater_than_or_equal_to(0) }
  end

  describe 'table name' do
    it 'uses the correct table name' do
      expect(described_class.table_name).to eq('import_placeholder_user_details')
    end
  end

  describe '.eligible_for_deletion' do
    let!(:eligible_record1) do
      create(:import_placeholder_user_details,
        :eligible_for_deletion
      )
    end

    let!(:eligible_record2) do
      create(:import_placeholder_user_details,
        deletion_attempts: 0,
        namespace: nil,
        last_deletion_attempt_at: nil
      )
    end

    let!(:ineligible_recent_attempt) do
      create(:import_placeholder_user_details,
        deletion_attempts: 1,
        namespace: nil,
        last_deletion_attempt_at: 1.day.ago
      )
    end

    let!(:ineligible_max_attempts) do
      create(:import_placeholder_user_details,
        deletion_attempts: 15,
        namespace: nil,
        last_deletion_attempt_at: 3.days.ago
      )
    end

    let!(:ineligible_group_present) do
      create(:import_placeholder_user_details)
    end

    it 'returns records marked for deletion with attempts under max and last attempt older than 2 days' do
      result = described_class.eligible_for_deletion

      expect(result).to include(eligible_record1)
      expect(result).to include(eligible_record2)
      expect(result).not_to include(ineligible_recent_attempt)
      expect(result).not_to include(ineligible_max_attempts)
      expect(result).not_to include(ineligible_group_present)
    end

    it 'includes records with nil last_deletion_attempt_at' do
      result = described_class.eligible_for_deletion

      expect(result).to include(eligible_record2)
    end
  end

  describe '#increment_deletion_attempt' do
    let(:placeholder_user_detail) { create(:import_placeholder_user_details, deletion_attempts: 2) }

    it 'increments the deletion_attempts counter' do
      expect { placeholder_user_detail.increment_deletion_attempt }
        .to change { placeholder_user_detail.reload.deletion_attempts }
        .from(2).to(3)
    end

    it 'updates the last_deletion_attempt_at timestamp' do
      freeze_time do
        expect { placeholder_user_detail.increment_deletion_attempt }
          .to change { placeholder_user_detail.reload.last_deletion_attempt_at }
          .from(nil).to(Time.current)
      end
    end
  end
end
