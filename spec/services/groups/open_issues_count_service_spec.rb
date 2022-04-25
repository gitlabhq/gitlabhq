# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::OpenIssuesCountService, :use_clean_rails_memory_store_caching do
  let_it_be(:group) { create(:group, :public)}
  let_it_be(:project) { create(:project, :public, namespace: group) }
  let_it_be(:user) { create(:user) }
  let_it_be(:issue) { create(:issue, :opened, project: project) }
  let_it_be(:confidential) { create(:issue, :opened, confidential: true, project: project) }
  let_it_be(:closed) { create(:issue, :closed, project: project) }

  subject { described_class.new(group, user) }

  describe '#relation_for_count' do
    before do
      allow(IssuesFinder).to receive(:new).and_call_original
    end

    it 'uses the IssuesFinder to scope issues' do
      expect(IssuesFinder)
        .to receive(:new)
        .with(user, group_id: group.id, state: 'opened', non_archived: true, include_subgroups: true, public_only: true)

      subject.count
    end
  end

  describe '#count' do
    context 'when user is nil' do
      it 'does not include confidential issues in the issue count' do
        expect(described_class.new(group).count).to eq(1)
      end
    end

    context 'when user is provided' do
      context 'when user can read confidential issues' do
        before do
          group.add_reporter(user)
        end

        it 'returns the right count with confidential issues' do
          expect(subject.count).to eq(2)
        end
      end

      context 'when user cannot read confidential issues' do
        before do
          group.add_guest(user)
        end

        it 'does not include confidential issues' do
          expect(subject.count).to eq(1)
        end
      end

      it_behaves_like 'a counter caching service with threshold'
    end
  end

  describe '#clear_all_cache_keys' do
    it 'calls `Rails.cache.delete` with the correct keys' do
      expect(Rails.cache).to receive(:delete)
        .with(['groups', 'open_issues_count_service', 1, group.id, described_class::PUBLIC_COUNT_KEY])
      expect(Rails.cache).to receive(:delete)
        .with(['groups', 'open_issues_count_service', 1, group.id, described_class::TOTAL_COUNT_KEY])

      subject.clear_all_cache_keys
    end
  end
end
