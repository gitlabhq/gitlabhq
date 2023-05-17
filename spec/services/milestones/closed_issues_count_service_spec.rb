# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Milestones::ClosedIssuesCountService, :use_clean_rails_memory_store_caching,
  feature_category: :team_planning do
  let(:project) { create(:project) }
  let(:milestone) { create(:milestone, project: project) }

  before do
    create(:issue, milestone: milestone, project: project)
    create(:issue, :confidential, milestone: milestone, project: project)

    create(:issue, :closed, milestone: milestone, project: project)
    create(:issue, :closed, :confidential, milestone: milestone, project: project)
  end

  subject { described_class.new(milestone) }

  it_behaves_like 'a counter caching service'

  it 'counts closed issues including confidential' do
    expect(subject.count).to eq(2)
  end
end
