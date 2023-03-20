# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::BatchStatusCleanerService, feature_category: :user_management do
  let_it_be(:user_status_1) { create(:user_status, emoji: 'coffee', message: 'msg1', clear_status_at: 1.year.ago) }
  let_it_be(:user_status_2) { create(:user_status, emoji: 'coffee', message: 'msg1', clear_status_at: 1.year.from_now) }
  let_it_be(:user_status_3) { create(:user_status, emoji: 'coffee', message: 'msg1', clear_status_at: 2.years.ago) }
  let_it_be(:user_status_4) { create(:user_status, emoji: 'coffee', message: 'msg1') }

  subject(:result) { described_class.execute }

  it 'cleans up scheduled user statuses' do
    expect(result[:deleted_rows]).to eq(2)

    deleted_statuses = UserStatus.where(user_id: [user_status_1.user_id, user_status_3.user_id])
    expect(deleted_statuses).to be_empty
  end

  it 'does not affect rows with future clear_status_at' do
    expect { result }.not_to change { user_status_2.reload }
  end

  it 'does not affect rows without clear_status_at' do
    expect { result }.not_to change { user_status_4.reload }
  end

  describe 'batch_size' do
    it 'clears status in batches' do
      result = described_class.execute(batch_size: 1)

      expect(result[:deleted_rows]).to eq(1)

      result = described_class.execute(batch_size: 1)

      expect(result[:deleted_rows]).to eq(1)

      result = described_class.execute(batch_size: 1)

      expect(result[:deleted_rows]).to eq(0)
    end
  end
end
