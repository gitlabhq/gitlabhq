# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::MergeRequestsCountService, :use_clean_rails_memory_store_caching do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, :public)}
  let_it_be(:project) { create(:project, :repository, namespace: group) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project, target_project: project) }

  subject { described_class.new(group, user) }

  describe '#relation_for_count' do
    before do
      group.add_reporter(user)
      allow(MergeRequestsFinder).to receive(:new).and_call_original
    end

    it 'uses the MergeRequestsFinder to scope merge requests' do
      expect(MergeRequestsFinder)
        .to receive(:new)
        .with(user, group_id: group.id, state: 'opened', non_archived: true, include_subgroups: true)

      subject.count
    end
  end

  it_behaves_like 'a counter caching service with threshold'
end
