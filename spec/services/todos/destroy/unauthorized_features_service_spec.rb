# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Todos::Destroy::UnauthorizedFeaturesService, feature_category: :team_planning do
  let_it_be(:project, reload: true) { create(:project, :public, :repository) }
  let_it_be(:issue)          { create(:issue, project: project) }
  let_it_be(:mr)             { create(:merge_request, source_project: project) }
  let_it_be(:user)           { create(:user) }
  let_it_be(:another_user)   { create(:user) }
  let_it_be(:project_member) do
    create(:user).tap do |user|
      project.add_developer(user)
    end
  end

  let!(:todo_mr_non_member)      { create(:todo, user: user, target: mr, project: project) }
  let!(:todo_mr_non_member2)     { create(:todo, user: another_user, target: mr, project: project) }
  let!(:todo_mr_member)          { create(:todo, user: project_member, target: mr, project: project) }
  let!(:todo_issue_non_member)   { create(:todo, user: user, target: issue, project: project) }
  let!(:todo_issue_non_member2)  { create(:todo, user: another_user, target: issue, project: project) }
  let!(:todo_issue_member)       { create(:todo, user: project_member, target: issue, project: project) }
  let!(:commit_todo_non_member)  { create(:on_commit_todo, user: user, project: project) }
  let!(:commit_todo_non_member2) { create(:on_commit_todo, user: another_user, project: project) }
  let!(:commit_todo_member)      { create(:on_commit_todo, user: project_member, project: project) }

  context 'when user_id is provided' do
    subject { described_class.new(project.id, user.id).execute }

    context 'when all features have same visibility as the project' do
      it 'removes only user issue todos' do
        expect { subject }.not_to change { Todo.count }
      end
    end

    context 'when issues are visible only to project members but the user is a member' do
      before do
        project.project_feature.update!(issues_access_level: ProjectFeature::PRIVATE)
        project.add_developer(user)
      end

      it 'does not remove any todos' do
        expect { subject }.not_to change { Todo.count }
      end
    end

    context 'when issues are visible only to project members' do
      before do
        project.project_feature.update!(issues_access_level: ProjectFeature::PRIVATE)
      end

      it 'removes only user issue todos' do
        expect { subject }.to change { Todo.count }.from(9).to(8)
      end
    end

    context 'when mrs, builds and repository are visible only to project members' do
      before do
        # builds and merge requests cannot have higher visibility than repository
        project.project_feature.update!(merge_requests_access_level: ProjectFeature::PRIVATE)
        project.project_feature.update!(builds_access_level: ProjectFeature::PRIVATE)
        project.project_feature.update!(repository_access_level: ProjectFeature::PRIVATE)
      end

      it 'removes only user mr and commit todos' do
        expect { subject }.to change { Todo.count }.from(9).to(7)
      end
    end

    context 'when mrs are visible only to project members' do
      before do
        project.project_feature.update!(merge_requests_access_level: ProjectFeature::PRIVATE)
      end

      it 'removes only user merge request todo' do
        expect { subject }.to change { Todo.count }.from(9).to(8)
      end
    end

    context 'when mrs and issues are visible only to project members' do
      before do
        project.project_feature.update!(issues_access_level: ProjectFeature::PRIVATE)
        project.project_feature.update!(merge_requests_access_level: ProjectFeature::PRIVATE)
      end

      it 'removes only user merge request and issue todos' do
        expect { subject }.to change { Todo.count }.from(9).to(7)
      end
    end
  end

  context 'when user_id is not provided' do
    subject { described_class.new(project.id).execute }

    context 'when all features have same visibility as the project' do
      it 'does not remove any todos' do
        expect { subject }.not_to change { Todo.count }
      end
    end

    context 'when issues are visible only to project members' do
      before do
        project.project_feature.update!(issues_access_level: ProjectFeature::PRIVATE)
      end

      it 'removes only non members issue todos' do
        expect { subject }.to change { Todo.count }.from(9).to(7)
      end
    end

    context 'when mrs, builds and repository are visible only to project members' do
      before do
        # builds and merge requests cannot have higher visibility than repository
        project.project_feature.update!(merge_requests_access_level: ProjectFeature::PRIVATE)
        project.project_feature.update!(builds_access_level: ProjectFeature::PRIVATE)
        project.project_feature.update!(repository_access_level: ProjectFeature::PRIVATE)
      end

      it 'removes only non members mr and commit todos' do
        expect { subject }.to change { Todo.count }.from(9).to(5)
      end
    end

    context 'when mrs are visible only to project members' do
      before do
        project.project_feature.update!(merge_requests_access_level: ProjectFeature::PRIVATE)
      end

      it 'removes only non members merge request todos' do
        expect { subject }.to change { Todo.count }.from(9).to(7)
      end
    end

    context 'when mrs and issues are visible only to project members' do
      before do
        project.project_feature.update!(issues_access_level: ProjectFeature::PRIVATE)
        project.project_feature.update!(merge_requests_access_level: ProjectFeature::PRIVATE)
      end

      it 'removes only non members merge request and issue todos' do
        expect { subject }.to change { Todo.count }.from(9).to(5)
      end
    end
  end
end
