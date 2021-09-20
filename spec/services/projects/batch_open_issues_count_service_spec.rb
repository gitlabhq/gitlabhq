# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::BatchOpenIssuesCountService do
  let!(:project_1) { create(:project) }
  let!(:project_2) { create(:project) }
  let!(:banned_user) { create(:user, :banned) }

  let(:subject) { described_class.new([project_1, project_2]) }

  describe '#refresh_cache_and_retrieve_data', :use_clean_rails_memory_store_caching do
    before do
      create(:issue, project: project_1)
      create(:issue, project: project_1, confidential: true)
      create(:issue, project: project_1, author: banned_user)
      create(:issue, project: project_2)
      create(:issue, project: project_2, confidential: true)
      create(:issue, project: project_2, author: banned_user)
    end

    context 'when cache is clean', :aggregate_failures do
      it 'refreshes cache keys correctly' do
        expect(get_cache_key(project_1)).to eq(nil)
        expect(get_cache_key(project_2)).to eq(nil)

        subject.count_service.new(project_1).refresh_cache
        subject.count_service.new(project_2).refresh_cache

        expect(get_cache_key(project_1)).to eq(1)
        expect(get_cache_key(project_2)).to eq(1)

        expect(get_cache_key(project_1, true)).to eq(2)
        expect(get_cache_key(project_2, true)).to eq(2)

        expect(get_cache_key(project_1, true, true)).to eq(3)
        expect(get_cache_key(project_2, true, true)).to eq(3)
      end
    end
  end

  def get_cache_key(project, with_confidential = false, with_hidden = false)
    service = subject.count_service.new(project)

    if with_confidential && with_hidden
      Rails.cache.read(service.cache_key(service.class::TOTAL_COUNT_KEY))
    elsif with_confidential
      Rails.cache.read(service.cache_key(service.class::TOTAL_COUNT_WITHOUT_HIDDEN_KEY))
    else
      Rails.cache.read(service.cache_key(service.class::PUBLIC_COUNT_WITHOUT_HIDDEN_KEY))
    end
  end
end
