# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::DeleteExpiredTriggerTokenWorker, feature_category: :continuous_integration do
  let_it_be(:project) { create(:project) }
  let_it_be(:owner) { create(:user) }

  let_it_be(:expired_and_retained_trigger) do
    create(:ci_trigger, owner: owner, project: project, expires_at: 1.day.ago)
  end

  let_it_be(:expired_and_deleted_trigger) do
    create(:ci_trigger, owner: owner, project: project, expires_at: 31.days.ago)
  end

  let_it_be(:not_expired_trigger) do
    create(:ci_trigger, owner: owner, project: project, expires_at: 1.day.from_now)
  end

  let_it_be(:never_expires_trigger) do
    create(:ci_trigger, owner: owner, project: project, expires_at: nil)
  end

  let_it_be(:worker) { described_class.new }

  describe '#perform' do
    it 'deletes only tokens that expired more than 30 days ago' do
      expect { worker.perform }.to change { Ci::Trigger.count }.by(-1)

      expect(Ci::Trigger.find_by(id: expired_and_deleted_trigger.id)).to be_nil
      expect(Ci::Trigger.find_by(id: expired_and_retained_trigger.id)).to be_present
      expect(Ci::Trigger.find_by(id: not_expired_trigger.id)).to be_present
      expect(Ci::Trigger.find_by(id: never_expires_trigger.id)).to be_present
    end

    it 'does not raise error when no trigger exists' do
      Ci::Trigger.delete_all

      expect { worker.perform }.not_to raise_error
    end

    it_behaves_like 'an idempotent worker'
  end
end
