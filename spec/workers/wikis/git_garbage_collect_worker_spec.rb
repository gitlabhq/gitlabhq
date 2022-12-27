# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Wikis::GitGarbageCollectWorker, feature_category: :source_code_management do
  it_behaves_like 'can collect git garbage' do
    let_it_be(:resource) { create(:project_wiki) }
    let_it_be(:page) { create(:wiki_page, wiki: resource) }

    let(:statistics_service_klass) { Projects::UpdateStatisticsService }
    let(:statistics_keys) { [:wiki_size] }
    let(:expected_default_lease) { "project_wikis:#{resource.id}" }
  end
end
