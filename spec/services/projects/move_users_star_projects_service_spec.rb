# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::MoveUsersStarProjectsService, feature_category: :groups_and_projects do
  let!(:user) { create(:user) }
  let!(:project_with_stars) { create(:project, namespace: user.namespace) }
  let!(:target_project) { create(:project, namespace: user.namespace) }

  subject { described_class.new(target_project, user) }

  describe '#execute' do
    before do
      create_list(:users_star_project, 2, project: project_with_stars)
    end

    it 'moves the user\'s stars from one project to another' do
      project_with_stars.reload
      target_project.reload

      expect(project_with_stars.users_star_projects.count).to eq 2
      expect(project_with_stars.star_count).to eq 2
      expect(target_project.users_star_projects.count).to eq 0
      expect(target_project.star_count).to eq 0

      subject.execute(project_with_stars)
      project_with_stars.reload
      target_project.reload

      expect(project_with_stars.users_star_projects.count).to eq 0
      expect(project_with_stars.star_count).to eq 0
      expect(target_project.users_star_projects.count).to eq 2
      expect(target_project.star_count).to eq 2
    end

    it 'rollbacks changes if transaction fails' do
      allow(subject).to receive(:success).and_raise(StandardError)

      expect { subject.execute(project_with_stars) }.to raise_error(StandardError)
      project_with_stars.reload
      target_project.reload

      expect(project_with_stars.users_star_projects.count).to eq 2
      expect(project_with_stars.star_count).to eq 2
      expect(target_project.users_star_projects.count).to eq 0
      expect(target_project.star_count).to eq 0
    end
  end
end
