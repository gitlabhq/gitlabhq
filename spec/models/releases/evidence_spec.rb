# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Releases::Evidence do
  let_it_be(:project) { create(:project) }

  let(:release) { create(:release, project: project) }

  describe 'associations' do
    it { is_expected.to belong_to(:release) }
  end

  it 'filters out issues from summary json' do
    milestone = create(:milestone, project: project, due_date: nil)
    issue = create(:issue, project: project, description: nil, state: 'closed')
    milestone.issues << issue
    release.milestones << milestone

    ::Releases::CreateEvidenceService.new(release).execute
    evidence = release.evidences.last

    expect(evidence.read_attribute(:summary)["release"]["milestones"].first["issues"].first["title"]).to be_present
    expect(evidence.summary["release"]["milestones"].first["issues"]).to be_nil
  end
end
