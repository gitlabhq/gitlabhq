# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::UnlinkProjectForksWorker, feature_category: :source_code_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }

  subject(:worker) { described_class.new }

  describe '#perform' do
    it 'calls UnlinkProjectForksService with correct arguments' do
      expect_next_instance_of(Namespaces::UnlinkProjectForksService, group, user) do |service|
        expect(service).to receive(:execute)
      end

      worker.perform(group.id, user.id)
    end

    context 'when group does not exist' do
      it 'does not raise an error' do
        expect { worker.perform(non_existing_record_id, user.id) }.not_to raise_error
      end

      it 'does not call UnlinkProjectForksService' do
        expect(Namespaces::UnlinkProjectForksService).not_to receive(:new)

        worker.perform(non_existing_record_id, user.id)
      end
    end

    context 'when user does not exist' do
      it 'does not raise an error' do
        expect { worker.perform(group.id, non_existing_record_id) }.not_to raise_error
      end

      it 'does not call UnlinkProjectForksService' do
        expect(Namespaces::UnlinkProjectForksService).not_to receive(:new)

        worker.perform(group.id, non_existing_record_id)
      end
    end
  end

  it_behaves_like 'an idempotent worker' do
    let(:job_args) { [group.id, user.id] }
  end
end
