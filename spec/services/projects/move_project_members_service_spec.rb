# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::MoveProjectMembersService, feature_category: :groups_and_projects do
  let!(:user) { create(:user) }
  let(:project_with_users) { create(:project, namespace: user.namespace) }
  let(:target_project) { create(:project, namespace: user.namespace) }
  let(:maintainer_user) { create(:user) }
  let(:reporter_user) { create(:user) }
  let(:developer_user) { create(:user) }

  subject { described_class.new(target_project, user) }

  describe '#execute' do
    before do
      project_with_users.add_maintainer(maintainer_user)
      project_with_users.add_developer(developer_user)
      project_with_users.add_reporter(reporter_user)
    end

    it 'moves the members from one project to another' do
      expect(project_with_users.project_members.count).to eq 4
      expect(target_project.project_members.count).to eq 1

      subject.execute(project_with_users)

      expect(project_with_users.project_members.count).to eq 0
      expect(target_project.project_members.count).to eq 4
    end

    it 'does not move existent members to the current project' do
      target_project.add_maintainer(developer_user)
      target_project.add_developer(reporter_user)

      expect(project_with_users.project_members.count).to eq 4
      expect(target_project.project_members.count).to eq 3

      subject.execute(project_with_users)

      expect(project_with_users.project_members.count).to eq 0
      expect(target_project.project_members.count).to eq 4
    end

    it 'rollbacks changes if transaction fails' do
      allow(subject).to receive(:success).and_raise(StandardError)

      expect { subject.execute(project_with_users) }.to raise_error(StandardError)

      expect(project_with_users.project_members.count).to eq 4
      expect(target_project.project_members.count).to eq 1
    end

    context 'when remove_remaining_elements is false' do
      let(:options) { { remove_remaining_elements: false } }

      it 'does not remove remaining project members' do
        target_project.add_maintainer(developer_user)
        target_project.add_developer(reporter_user)

        subject.execute(project_with_users, **options)

        expect(project_with_users.project_members.count).not_to eq 0
      end
    end
  end
end
