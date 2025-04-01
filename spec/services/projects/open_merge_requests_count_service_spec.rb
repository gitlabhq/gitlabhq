# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::OpenMergeRequestsCountService, :use_clean_rails_memory_store_caching, feature_category: :code_review_workflow do
  let_it_be(:project) { create(:project) }

  subject { described_class.new(project) }

  it_behaves_like 'a counter caching service'

  describe '#count' do
    it 'returns the number of open merge requests' do
      create(:merge_request, :opened, source_project: project, target_project: project)

      expect(subject.count).to eq(1)
    end

    context 'when there are hidden merge requests' do
      let(:banned_user) { create(:user, :banned) }

      before do
        create(:merge_request, :opened, source_project: project, target_project: project, source_branch: 'user-branch')
        create(:merge_request, :opened, source_project: project, target_project: project,
          source_branch: 'banned-user-branch', author: banned_user)
      end

      it 'does not include hidden merge requests in the count' do
        expect(described_class.new(project).count).to eq(1)
      end
    end
  end
end
