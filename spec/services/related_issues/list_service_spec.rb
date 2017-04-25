require 'spec_helper'

describe RelatedIssues::ListService, service: true do
  describe '#execute' do
    let(:user) { create :user }
    let(:project) { create(:project_empty_repo) }
    let(:issue) { create :issue, project: project }

    let(:issue_b) { create :issue, project: project }
    let(:issue_c) { create :issue, project: project }
    let(:issue_d) { create :issue, project: project }

    let!(:related_issue_c) do
      create(:related_issue, issue: issue_d,
                             related_issue: issue,
                             created_at: Date.today)
    end

    let!(:related_issue_b) do
      create(:related_issue, issue: issue,
                             related_issue: issue_c,
                             created_at: 1.day.ago)
    end

    let!(:related_issue_a) do
      create(:related_issue, issue: issue,
                             related_issue: issue_b,
                             created_at: 2.days.ago)
    end

    subject { described_class.new(issue, user).execute }

    it 'verifies number of queries' do
      recorded = ActiveRecord::QueryRecorder.new { subject }
      expect(recorded.count).to be_within(1).of(29)
    end

    it 'returns related issues JSON' do
      expect(subject.size).to eq(3)

      expect(subject[0]).to eq(
        {
          title: issue_b.title,
          state: issue_b.state,
          reference: issue_b.to_reference(project),
          path: "/#{project.full_path}/issues/#{issue_b.iid}"
        }
      )

      expect(subject[1]).to eq(
        {
          title: issue_c.title,
          state: issue_c.state,
          reference: issue_c.to_reference(project),
          path: "/#{project.full_path}/issues/#{issue_c.iid}"
        }
      )

      expect(subject[2]).to eq(
        {
          title: issue_d.title,
          state: issue_d.state,
          reference: issue_d.to_reference(project),
          path: "/#{project.full_path}/issues/#{issue_d.iid}"
        }
      )
    end
  end
end
