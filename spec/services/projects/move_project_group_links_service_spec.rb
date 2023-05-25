# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::MoveProjectGroupLinksService, feature_category: :groups_and_projects do
  let!(:user) { create(:user) }
  let(:project_with_groups) { create(:project, namespace: user.namespace) }
  let(:target_project) { create(:project, namespace: user.namespace) }
  let(:maintainer_group) { create(:group) }
  let(:reporter_group) { create(:group) }
  let(:developer_group) { create(:group) }

  subject { described_class.new(target_project, user) }

  describe '#execute' do
    before do
      project_with_groups.project_group_links.create!(group: maintainer_group, group_access: Gitlab::Access::MAINTAINER)
      project_with_groups.project_group_links.create!(group: developer_group, group_access: Gitlab::Access::DEVELOPER)
      project_with_groups.project_group_links.create!(group: reporter_group, group_access: Gitlab::Access::REPORTER)
    end

    it 'moves the group links from one project to another' do
      expect(project_with_groups.project_group_links.count).to eq 3
      expect(target_project.project_group_links.count).to eq 0

      subject.execute(project_with_groups)

      expect(project_with_groups.project_group_links.count).to eq 0
      expect(target_project.project_group_links.count).to eq 3
    end

    it 'does not move existent group links in the current project' do
      target_project.project_group_links.create!(group: maintainer_group, group_access: Gitlab::Access::MAINTAINER)
      target_project.project_group_links.create!(group: developer_group, group_access: Gitlab::Access::DEVELOPER)

      expect(project_with_groups.project_group_links.count).to eq 3
      expect(target_project.project_group_links.count).to eq 2

      subject.execute(project_with_groups)

      expect(project_with_groups.project_group_links.count).to eq 0
      expect(target_project.project_group_links.count).to eq 3
    end

    it 'rollbacks changes if transaction fails' do
      allow(subject).to receive(:success).and_raise(StandardError)

      expect { subject.execute(project_with_groups) }.to raise_error(StandardError)

      expect(project_with_groups.project_group_links.count).to eq 3
      expect(target_project.project_group_links.count).to eq 0
    end

    context 'when remove_remaining_elements is false' do
      let(:options) { { remove_remaining_elements: false } }

      it 'does not remove remaining project group links' do
        target_project.project_group_links.create!(group: maintainer_group, group_access: Gitlab::Access::MAINTAINER)
        target_project.project_group_links.create!(group: developer_group, group_access: Gitlab::Access::DEVELOPER)

        subject.execute(project_with_groups, **options)

        expect(project_with_groups.project_group_links.count).not_to eq 0
      end
    end
  end
end
