# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::MoveProjectAuthorizationsService, feature_category: :groups_and_projects do
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

    it 'moves the authorizations from one project to another' do
      expect(project_with_users.authorized_users.count).to eq 4
      expect(target_project.authorized_users.count).to eq 1

      subject.execute(project_with_users)

      expect(project_with_users.authorized_users.count).to eq 0
      expect(target_project.authorized_users.count).to eq 4
    end

    it 'does not move existent authorizations to the current project' do
      target_project.add_maintainer(developer_user)
      target_project.add_developer(reporter_user)

      expect(project_with_users.authorized_users.count).to eq 4
      expect(target_project.authorized_users.count).to eq 3

      subject.execute(project_with_users)

      expect(project_with_users.authorized_users.count).to eq 0
      expect(target_project.authorized_users.count).to eq 4
    end

    context 'when remove_remaining_elements is false' do
      let(:options) { { remove_remaining_elements: false } }

      it 'does not remove remaining project authorizations' do
        target_project.add_maintainer(developer_user)
        target_project.add_developer(reporter_user)

        subject.execute(project_with_users, **options)

        expect(project_with_users.project_authorizations.count).not_to eq 0
      end
    end
  end
end
