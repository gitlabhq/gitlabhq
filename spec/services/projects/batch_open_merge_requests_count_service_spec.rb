# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::BatchOpenMergeRequestsCountService, feature_category: :code_review_workflow do
  subject { described_class.new([project_1, project_2]) }

  let_it_be(:project_1) { create(:project) }
  let_it_be(:project_2) { create(:project) }

  describe '#refresh_cache_and_retrieve_data', :use_clean_rails_memory_store_caching do
    before do
      create(:merge_request, source_project: project_1, target_project: project_1)
      create(:merge_request, source_project: project_2, target_project: project_2)
    end

    it 'refreshes cache keys correctly when cache is clean', :aggregate_failures do
      subject.refresh_cache_and_retrieve_data

      expect(Rails.cache.read(get_cache_key(subject, project_1))).to eq(1)
      expect(Rails.cache.read(get_cache_key(subject, project_2))).to eq(1)

      expect { subject.refresh_cache_and_retrieve_data }.not_to exceed_query_limit(0)
    end
  end

  def get_cache_key(subject, project)
    subject.count_service
      .new(project)
      .cache_key
  end
end
