require 'spec_helper'

describe RelatedIssues::ListService, service: true do
  let(:user) { create :user }
  let(:project) { create(:project_empty_repo) }
  let(:issue) { create :issue, project: project }

  before do
    project.team << [user, :developer]
  end

  describe '#execute' do
    subject { described_class.new(issue, user).execute }

    context 'user can see all issues' do
      let(:issue_b) { create :issue, project: project }
      let(:issue_c) { create :issue, project: project }
      let(:issue_d) { create :issue, project: project }

      let!(:related_issue_c) do
        create(:related_issue, id: 999,
                               issue: issue_d,
                               related_issue: issue,
                               created_at: Date.today)
      end

      let!(:related_issue_b) do
        create(:related_issue, id: 998,
                               issue: issue,
                               related_issue: issue_c,
                               created_at: 1.day.ago)
      end

      let!(:related_issue_a) do
        create(:related_issue, id: 997,
                               issue: issue,
                               related_issue: issue_b,
                               created_at: 2.days.ago)
      end

      it 'verifies number of queries' do
        recorded = ActiveRecord::QueryRecorder.new { subject }
        expect(recorded.count).to be_within(1).of(25)
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

    context 'user cannot see relations' do
      context 'when user cannot see the referenced issue' do
        let!(:related_issue) do
          create(:related_issue, issue: issue)
        end

        it 'returns an empty list' do
          is_expected.to eq([])
        end
      end

      context 'when user cannot see the issue that referenced' do
        let!(:related_issue) do
          create(:related_issue, related_issue: issue)
        end

        it 'returns an empty list' do
          is_expected.to eq([])
        end
      end
    end
  end
end
