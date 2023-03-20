# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Todos::Destroy::ProjectPrivateService, feature_category: :team_planning do
  let(:group)          { create(:group, :public) }
  let(:project)        { create(:project, :public, group: group) }
  let(:user)           { create(:user) }
  let(:project_member) { create(:user) }
  let(:group_member)   { create(:user) }

  let!(:todo_non_member)   { create(:todo, user: user, project: project) }
  let!(:todo2_non_member)  { create(:todo, user: user, project: project) }
  let!(:todo_member)       { create(:todo, user: project_member, project: project) }
  let!(:todo_group_member) { create(:todo, user: group_member, project: project) }

  describe '#execute' do
    before do
      project.add_developer(project_member)
      group.add_developer(group_member)
    end

    subject { described_class.new(project.id).execute }

    context 'when a project set to private' do
      before do
        project.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
      end

      it 'removes issue todos for a user who is not a member' do
        expect { subject }.to change { Todo.count }.from(4).to(2)

        expect(user.todos).to be_empty
        expect(project_member.todos).to match_array([todo_member])
        expect(group_member.todos).to match_array([todo_group_member])
      end
    end

    context 'when project is not private' do
      it 'does not remove any todos' do
        expect { subject }.not_to change { Todo.count }
      end
    end
  end
end
