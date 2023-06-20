# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::BatchOpenIssuesCountService, feature_category: :groups_and_projects do
  let!(:project_1) { create(:project) }
  let!(:project_2) { create(:project) }

  let(:subject) { described_class.new([project_1, project_2]) }

  describe '#refresh_cache_and_retrieve_data', :use_clean_rails_memory_store_caching do
    before do
      create(:issue, project: project_1)
      create(:issue, project: project_1, confidential: true)

      create(:issue, project: project_2)
      create(:issue, project: project_2, confidential: true)
    end

    context 'when cache is clean' do
      it 'refreshes cache keys correctly' do
        subject.refresh_cache_and_retrieve_data

        # It does not update total issues cache
        expect(Rails.cache.read(get_cache_key(subject, project_1))).to eq(nil)
        expect(Rails.cache.read(get_cache_key(subject, project_2))).to eq(nil)

        expect(Rails.cache.read(get_cache_key(subject, project_1, true))).to eq(1)
        expect(Rails.cache.read(get_cache_key(subject, project_1, true))).to eq(1)
      end
    end
  end

  def get_cache_key(subject, project, public_key = false)
    service = subject.count_service.new(project)

    if public_key
      service.cache_key(service.class::PUBLIC_COUNT_KEY)
    else
      service.cache_key(service.class::TOTAL_COUNT_KEY)
    end
  end
end
