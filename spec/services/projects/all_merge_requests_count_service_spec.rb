# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::AllMergeRequestsCountService, :use_clean_rails_memory_store_caching, feature_category: :groups_and_projects do
  let_it_be(:project) { create(:project) }

  subject { described_class.new(project) }

  it_behaves_like 'a counter caching service'

  describe '#count' do
    it 'returns the number of all merge requests' do
      create(:merge_request, :opened, source_project: project, target_project: project)
      create(:merge_request, :closed, source_project: project, target_project: project)
      create(:merge_request, :merged, source_project: project, target_project: project)

      expect(subject.count).to eq(3)
    end
  end
end
