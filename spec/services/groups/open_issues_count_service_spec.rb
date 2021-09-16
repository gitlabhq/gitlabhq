# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::OpenIssuesCountService, :use_clean_rails_memory_store_caching do
  let_it_be(:group) { create(:group, :public) }
  let_it_be(:project) { create(:project, :public, namespace: group) }
  let_it_be(:admin) { create(:user, :admin) }
  let_it_be(:user) { create(:user) }
  let_it_be(:banned_user) { create(:user, :banned) }

  before do
    create(:issue, :opened, project: project)
    create(:issue, :opened, confidential: true, project: project)
    create(:issue, :opened, author: banned_user, project: project)
    create(:issue, :closed, project: project)
  end

  subject { described_class.new(group, user) }

  describe '#relation_for_count' do
    before do
      allow(IssuesFinder).to receive(:new).and_call_original
    end

    it 'uses the IssuesFinder to scope issues' do
      expect(IssuesFinder)
        .to receive(:new)
        .with(user, group_id: group.id, state: 'opened', non_archived: true, include_subgroups: true, public_only: true, include_hidden: false)

      subject.count
    end
  end

  describe '#count' do
    shared_examples 'counts public issues, does not count hidden or confidential' do
      it 'counts only public issues' do
        expect(subject.count).to eq(1)
      end

      it 'uses PUBLIC_COUNT_WITHOUT_HIDDEN_KEY cache key' do
        expect(subject.cache_key).to include('group_open_public_issues_without_hidden_count')
      end
    end

    context 'when user is nil' do
      let(:user) { nil }

      it_behaves_like 'counts public issues, does not count hidden or confidential'
    end

    context 'when user is provided' do
      context 'when user can read confidential issues' do
        before do
          group.add_reporter(user)
        end

        it 'includes confidential issues and does not include hidden issues in count' do
          expect(subject.count).to eq(2)
        end

        it 'uses TOTAL_COUNT_WITHOUT_HIDDEN_KEY cache key' do
          expect(subject.cache_key).to include('group_open_issues_without_hidden_count')
        end
      end

      context 'when user cannot read confidential issues' do
        before do
          group.add_guest(user)
        end

        it_behaves_like 'counts public issues, does not count hidden or confidential'
      end

      context 'when user is an admin' do
        let(:user) { admin }

        context 'when admin mode is enabled', :enable_admin_mode do
          it 'includes confidential and hidden issues in count' do
            expect(subject.count).to eq(3)
          end

          it 'uses TOTAL_COUNT_KEY cache key' do
            expect(subject.cache_key).to include('group_open_issues_including_hidden_count')
          end
        end

        context 'when admin mode is disabled' do
          it_behaves_like 'counts public issues, does not count hidden or confidential'
        end
      end

      it_behaves_like 'a counter caching service with threshold'
    end
  end

  describe '#clear_all_cache_keys' do
    it 'calls `Rails.cache.delete` with the correct keys' do
      expect(Rails.cache).to receive(:delete)
        .with(['groups', 'open_issues_count_service', 1, group.id, described_class::PUBLIC_COUNT_WITHOUT_HIDDEN_KEY])
      expect(Rails.cache).to receive(:delete)
        .with(['groups', 'open_issues_count_service', 1, group.id, described_class::TOTAL_COUNT_KEY])
      expect(Rails.cache).to receive(:delete)
        .with(['groups', 'open_issues_count_service', 1, group.id, described_class::TOTAL_COUNT_WITHOUT_HIDDEN_KEY])

      described_class.new(group).clear_all_cache_keys
    end
  end
end
