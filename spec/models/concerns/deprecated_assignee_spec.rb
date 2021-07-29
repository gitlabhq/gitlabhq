# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DeprecatedAssignee do
  let(:user) { create(:user) }

  describe '#assignee_id=' do
    it 'creates the merge_request_assignees relation' do
      merge_request = create(:merge_request, assignee_id: user.id)

      merge_request.reload

      expect(merge_request.merge_request_assignees.count).to eq(1)
    end

    it 'nullifies the assignee_id column' do
      merge_request = create(:merge_request, assignee_id: user.id)

      merge_request.reload

      expect(merge_request.read_attribute(:assignee_id)).to be_nil
    end

    context 'when relation already exists' do
      it 'overwrites existing assignees' do
        other_user = create(:user)
        merge_request = create(:merge_request, assignee_id: nil)
        merge_request.merge_request_assignees.create!(user_id: user.id)
        merge_request.merge_request_assignees.create!(user_id: other_user.id)

        expect { merge_request.update!(assignee_id: other_user.id) }
          .to change { merge_request.reload.merge_request_assignees.count }
          .from(2).to(1)
      end
    end
  end

  describe '#assignee=' do
    it 'creates the merge_request_assignees relation' do
      merge_request = create(:merge_request, assignee: user)

      merge_request.reload

      expect(merge_request.merge_request_assignees.count).to eq(1)
    end

    it 'nullifies the assignee_id column' do
      merge_request = create(:merge_request, assignee: user)

      merge_request.reload

      expect(merge_request.read_attribute(:assignee_id)).to be_nil
    end

    context 'when relation already exists' do
      it 'overwrites existing assignees' do
        other_user = create(:user)
        merge_request = create(:merge_request, assignee: nil)
        merge_request.merge_request_assignees.create!(user_id: user.id)
        merge_request.merge_request_assignees.create!(user_id: other_user.id)

        expect { merge_request.update!(assignee: other_user) }
          .to change { merge_request.reload.merge_request_assignees.count }
          .from(2).to(1)
      end
    end
  end

  describe '#assignee_id' do
    it 'returns the first assignee ID' do
      other_user = create(:user)
      merge_request = create(:merge_request, assignees: [user, other_user])

      merge_request.reload

      expect(merge_request.assignee_id).to eq(merge_request.assignee_ids.first)
    end
  end

  describe '#assignees' do
    context 'when assignee_id exists and there is no relation' do
      it 'creates the relation' do
        merge_request = create(:merge_request, assignee_id: nil)
        merge_request.update_column(:assignee_id, user.id)

        expect { merge_request.assignees }.to change { merge_request.merge_request_assignees.count }.from(0).to(1)
      end

      it 'nullifies the assignee_id' do
        merge_request = create(:merge_request, assignee_id: nil)
        merge_request.update_column(:assignee_id, user.id)

        expect { merge_request.assignees }
          .to change { merge_request.read_attribute(:assignee_id) }
          .from(user.id).to(nil)
      end
    end

    context 'when DB is read-only' do
      before do
        allow(Gitlab::Database.main).to receive(:read_only?) { true }
      end

      it 'returns a users relation' do
        merge_request = create(:merge_request, assignee_id: user.id)

        expect(merge_request.assignees).to be_a(ActiveRecord::Relation)
        expect(merge_request.assignees).to eq([user])
      end

      it 'returns an empty relation if no assignee_id is set' do
        merge_request = create(:merge_request, assignee_id: nil)

        expect(merge_request.assignees).to be_a(ActiveRecord::Relation)
        expect(merge_request.assignees).to eq([])
      end
    end
  end

  describe '#assignee_ids' do
    context 'when assignee_id exists and there is no relation' do
      it 'creates the relation' do
        merge_request = create(:merge_request, assignee_id: nil)
        merge_request.update_column(:assignee_id, user.id)

        expect { merge_request.assignee_ids }.to change { merge_request.merge_request_assignees.count }.from(0).to(1)
      end

      it 'nullifies the assignee_id' do
        merge_request = create(:merge_request, assignee_id: nil)
        merge_request.update_column(:assignee_id, user.id)

        expect { merge_request.assignee_ids }
          .to change { merge_request.read_attribute(:assignee_id) }
          .from(user.id).to(nil)
      end
    end

    context 'when DB is read-only' do
      before do
        allow(Gitlab::Database.main).to receive(:read_only?) { true }
      end

      it 'returns a list of user IDs' do
        merge_request = create(:merge_request, assignee_id: user.id)

        expect(merge_request.assignee_ids).to be_a(Array)
        expect(merge_request.assignee_ids).to eq([user.id])
      end

      it 'returns an empty relation if no assignee_id is set' do
        merge_request = create(:merge_request, assignee_id: nil)

        expect(merge_request.assignee_ids).to be_a(Array)
        expect(merge_request.assignee_ids).to eq([])
      end
    end
  end
end
