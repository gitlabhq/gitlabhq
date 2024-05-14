# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IssueLinks::ListService, feature_category: :team_planning do
  let(:user) { create :user }
  let(:project) { create(:project_empty_repo, :private) }
  let(:issue) { create :issue, project: project }
  let(:user_role) { :guest }

  before do
    project.add_role(user, user_role) if user_role
  end

  describe '#execute' do
    subject { described_class.new(issue, user).execute }

    context 'user can see all issues' do
      let(:issue_b) { create :issue, project: project }
      let(:issue_c) { create :issue, project: project }
      let(:issue_d) { create :issue, project: project }

      let!(:issue_link_c) do
        create(:issue_link, source: issue_d, target: issue)
      end

      let!(:issue_link_b) do
        create(:issue_link, source: issue, target: issue_c)
      end

      let!(:issue_link_a) do
        create(:issue_link, source: issue, target: issue_b)
      end

      it 'ensures no N+1 queries are made' do
        control = ActiveRecord::QueryRecorder.new { subject }

        project = create :project, :public
        milestone = create :milestone, project: project
        issue_x = create :issue, project: project, milestone: milestone
        issue_y = create :issue, project: project, assignees: [user]
        issue_z = create :issue, project: project
        create :issue_link, source: issue_x, target: issue_y
        create :issue_link, source: issue_x, target: issue_z
        create :issue_link, source: issue_y, target: issue_z

        expect { subject }.not_to exceed_query_limit(control)
      end

      it 'returns related issues JSON' do
        expect(subject.size).to eq(3)

        expect(subject).to include(include(
          id: issue_b.id,
          title: issue_b.title,
          state: issue_b.state,
          reference: issue_b.to_reference(project),
          path: "/#{project.full_path}/-/issues/#{issue_b.iid}",
          relation_path: "/#{project.full_path}/-/issues/#{issue.iid}/links/#{issue_link_a.id}"
        ))

        expect(subject).to include(include(
          id: issue_c.id,
          title: issue_c.title,
          state: issue_c.state,
          reference: issue_c.to_reference(project),
          path: "/#{project.full_path}/-/issues/#{issue_c.iid}",
          relation_path: "/#{project.full_path}/-/issues/#{issue.iid}/links/#{issue_link_b.id}"
        ))

        expect(subject).to include(include(
          id: issue_d.id,
          title: issue_d.title,
          state: issue_d.state,
          reference: issue_d.to_reference(project),
          path: "/#{project.full_path}/-/issues/#{issue_d.iid}",
          relation_path: "/#{project.full_path}/-/issues/#{issue.iid}/links/#{issue_link_c.id}"
        ))
      end
    end

    context 'referencing a public project issue' do
      let(:public_project) { create :project, :public }
      let(:issue_b) { create :issue, project: public_project }

      let!(:issue_link) do
        create(:issue_link, source: issue, target: issue_b)
      end

      it 'presents issue' do
        expect(subject.size).to eq(1)
      end
    end

    context 'referencing issue with removed relationships' do
      context 'when referenced a deleted issue' do
        let(:issue_b) { create :issue, project: project }
        let!(:issue_link) do
          create(:issue_link, source: issue, target: issue_b)
        end

        it 'ignores issue' do
          issue_b.destroy!

          is_expected.to eq([])
        end
      end

      context 'when referenced an issue with deleted project' do
        let(:issue_b) { create :issue, project: project }
        let!(:issue_link) do
          create(:issue_link, source: issue, target: issue_b)
        end

        it 'ignores issue' do
          project.destroy!

          is_expected.to eq([])
        end
      end

      context 'when referenced an issue with deleted namespace' do
        let(:issue_b) { create :issue, project: project }
        let!(:issue_link) do
          create(:issue_link, source: issue, target: issue_b)
        end

        it 'ignores issue' do
          project.namespace.destroy!

          is_expected.to eq([])
        end
      end
    end

    context 'user cannot see relations' do
      context 'when user cannot see the referenced issue' do
        let!(:issue_link) do
          create(:issue_link, source: issue)
        end

        it 'returns an empty list' do
          is_expected.to eq([])
        end
      end

      context 'when user cannot see the issue that referenced' do
        let!(:issue_link) do
          create(:issue_link, target: issue)
        end

        it 'returns an empty list' do
          is_expected.to eq([])
        end
      end
    end

    context 'remove relations' do
      let!(:issue_link) do
        create(:issue_link, source: issue, target: referenced_issue)
      end

      context 'user can admin related issues just on target project' do
        let(:user_role) { nil }
        let(:target_project) { create :project }
        let(:referenced_issue) { create :issue, project: target_project }

        it 'returns no destroy relation path' do
          target_project.add_guest(user)

          expect(subject.first[:relation_path]).to be_nil
        end
      end

      context 'user can admin related issues just on source project' do
        let(:target_project) { create :project, :public }
        let(:user_role) { :guest }
        let(:referenced_issue) { create :issue, project: target_project }

        it 'returns no destroy relation path' do
          expect(subject.first[:relation_path]).to be_nil
        end
      end

      context 'when user can admin related issues on both projects' do
        let(:referenced_issue) { create :issue, project: project }

        it 'returns related issue destroy relation path' do
          expect(subject.first[:relation_path])
            .to eq("/#{project.full_path}/-/issues/#{issue.iid}/links/#{issue_link.id}")
        end
      end
    end
  end
end
