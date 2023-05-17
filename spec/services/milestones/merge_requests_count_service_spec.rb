# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Milestones::MergeRequestsCountService, :use_clean_rails_memory_store_caching,
  feature_category: :team_planning do
  let_it_be(:project) { create(:project, :empty_repo) }
  let_it_be(:milestone) { create(:milestone, project: project) }

  before_all do
    create(:merge_request, milestone: milestone, source_project: project)
    create(:merge_request, :closed, milestone: milestone, source_project: project)
  end

  subject { described_class.new(milestone) }

  it_behaves_like 'a counter caching service'

  it 'counts all merge requests' do
    expect(subject.count).to eq(2)
  end
end
