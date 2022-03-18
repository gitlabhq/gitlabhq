# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Quality::TestDataCleanupWorker do
  subject { described_class.new }

  shared_examples 'successful deletion' do
    before do
      allow(Gitlab).to receive(:staging?).and_return(true)
    end

    it 'removes test groups' do
      expect { subject.perform }.to change(Group, :count).by(-test_group_count)
    end
  end

  describe "#perform" do
    context 'with multiple test groups to remove' do
      let(:test_group_count) { 5 }
      let!(:groups_to_remove) { create_list(:group, test_group_count, :test_group) }
      let!(:group_to_keep) { create(:group, path: 'test-group-fulfillment-keep', created_at: 1.day.ago) }
      let!(:non_test_group) { create(:group) }
      let(:non_test_owner_group) { create(:group, path: 'test-group-fulfillment1234', created_at: 4.days.ago) }

      before do
        non_test_owner_group.add_owner(create(:user))
      end

      it_behaves_like 'successful deletion'
    end

    context 'with paid groups' do
      let(:test_group_count) { 1 }
      let!(:paid_group) { create(:group, :test_group) }

      before do
        allow(paid_group).to receive(:paid?).and_return(true)
      end

      it_behaves_like 'successful deletion'
    end
  end
end
