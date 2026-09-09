# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authz::ProjectAuthorizationReverification, feature_category: :permissions do
  describe 'associations' do
    it { is_expected.to belong_to(:user).required }
  end

  describe '.abandoned' do
    subject(:abandoned) { described_class.abandoned }

    let_it_be(:stale) { create(:project_authorization_reverification, :abandoned) }
    let_it_be(:recently_started) { create(:project_authorization_reverification, :processing) }
    let_it_be(:too_recent) { create(:project_authorization_reverification) }

    it 'returns only processing records older than the timeout' do
      expect(abandoned).to contain_exactly(stale)
    end
  end

  describe '.to_be_processed' do
    subject(:to_be_processed) { described_class.to_be_processed }

    let_it_be(:old_enough) { create(:project_authorization_reverification, :to_be_processed) }
    let_it_be(:requeued) { create(:project_authorization_reverification, :requeued, :to_be_processed) }
    let_it_be(:processing) { create(:project_authorization_reverification, :processing) }
    let_it_be(:too_recent) { create(:project_authorization_reverification) }

    it 'returns pending and requeued records older than MIN_AGE' do
      expect(to_be_processed).to contain_exactly(old_enough, requeued)
    end
  end

  describe '.claim_batch' do
    subject(:claim_batch) { described_class.claim_batch }

    context 'when a pending record is eligible' do
      let_it_be(:reverification) { create(:project_authorization_reverification, :to_be_processed) }

      it 'returns the claimed records' do
        expect(claim_batch).to contain_exactly(reverification)
      end

      it 'updates the claimed records as processing' do
        expect { claim_batch }.to change { reverification.reload.status }.from('pending').to('processing')
      end

      it 'updates refresh_started_at on the claimed records' do
        expect { claim_batch }.to change { reverification.reload.refresh_started_at }.from(nil)
      end
    end

    context 'when a record was requeued mid-refresh' do
      let_it_be(:requeued) { create(:project_authorization_reverification, :requeued, :to_be_processed) }

      it 'claims it alongside pending records' do
        expect(claim_batch).to contain_exactly(requeued)
      end
    end

    context 'when more records are eligible than CLAIM_BATCH_SIZE' do
      let_it_be(:reverifications) { create_list(:project_authorization_reverification, 2, :to_be_processed) }

      before do
        stub_const("#{described_class}::CLAIM_BATCH_SIZE", 1)
      end

      it 'claims no more than CLAIM_BATCH_SIZE records' do
        expect(claim_batch.size).to eq(1)
      end
    end

    context 'when all records have been claimed' do
      let_it_be(:claimed) do
        create(:project_authorization_reverification, :processing, :to_be_processed)
      end

      it 'returns an empty result without claiming anything' do
        expect(claim_batch).to be_empty
        expect(claimed.reload).to be_processing
      end
    end
  end

  describe '.queue_users' do
    subject(:queue_users) { described_class.queue_users(user_ids) }

    context 'when none of the users are queued' do
      let_it_be(:users) { create_list(:user, 3) }
      let_it_be(:user_ids) { users.map(&:id) }

      it 'queues the users as pending' do
        expect { queue_users }.to change { described_class.pending.count }.by(3)
      end
    end

    context 'when one of the users is already queued' do
      let_it_be(:users) { create_list(:user, 3) }
      let_it_be(:user_ids) { users.map(&:id) }

      before do
        described_class.queue_users([user_ids.first])
      end

      it 'does not duplicate users that are already queued' do
        expect { queue_users }.to change { described_class.count }.by(2)
      end
    end

    context 'when the user is already being processed' do
      let_it_be(:user) { create(:user) }
      let_it_be(:user_ids) { [user.id] }
      let_it_be(:reverification) do
        create(:project_authorization_reverification, :processing, user: user, enqueued_at: 1.day.ago)
      end

      it 'requeues the record' do
        expect { queue_users }
          .to change { reverification.reload.status }.from('processing').to('requeued')
          .and change { reverification.reload.enqueued_at }
      end
    end

    context 'when the user is already queued as pending' do
      let_it_be(:user) { create(:user) }
      let_it_be(:user_ids) { [user.id] }
      let_it_be(:reverification) do
        create(:project_authorization_reverification, user: user, enqueued_at: 1.day.ago)
      end

      it 'leaves the existing record untouched' do
        expect { queue_users }
          .to not_change { reverification.reload.status }.from('pending')
          .and not_change { reverification.reload.enqueued_at }
      end
    end

    context 'when a user id has no matching user' do
      let_it_be(:user) { create(:user) }
      let_it_be(:user_ids) { [user.id, non_existing_record_id] }

      it 'queues the existing users and skips the non-existent one' do
        expect { queue_users }.to change { described_class.count }.by(1)
      end
    end
  end

  describe '#processed' do
    subject(:processed) { reverification.processed }

    context 'when the record is finished processing' do
      let_it_be(:reverification) { create(:project_authorization_reverification, :processing) }

      it 'removes a record that is still processing' do
        expect { processed }.to change { described_class.count }.by(-1)
      end
    end

    context 'when the record was requeued mid-refresh' do
      let_it_be(:reverification) { create(:project_authorization_reverification, :requeued) }

      it 'leaves a record that was requeued mid-refresh' do
        expect { processed }.not_to change { described_class.count }
      end
    end
  end
end
