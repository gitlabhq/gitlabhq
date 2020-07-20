# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Evidences::MilestoneEntity do
  let(:milestone) { build(:milestone) }
  let(:entity) { described_class.new(milestone) }

  subject { entity.as_json }

  it 'exposes the expected fields' do
    expect(subject.keys).to contain_exactly(:id, :title, :description, :state, :iid, :created_at, :due_date, :issues)
  end

  context 'when there are issues linked to this milestone' do
    let(:issue_1) { build(:issue) }
    let(:issue_2) { build(:issue) }
    let(:milestone) { build(:milestone, issues: [issue_1, issue_2]) }

    it 'exposes these issues' do
      expect(subject[:issues]).to contain_exactly(
        Evidences::IssueEntity.new(issue_1).as_json,
        Evidences::IssueEntity.new(issue_2).as_json
      )
    end
  end

  context 'when the release has no milestone' do
    let(:milestone) { build(:milestone, issues: []) }

    it 'exposes an empty array for milestones' do
      expect(subject[:issues]).to be_empty
    end
  end
end
