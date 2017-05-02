# encoding: utf-8

require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20170502101023_clean_up_pending_delete_projects.rb')

describe CleanUpPendingDeleteProjects do
  let(:migration) { described_class.new }
  let!(:admin) { create(:admin) }
  let!(:project) { create(:empty_project, pending_delete: true) }

  describe '#up' do
    it 'only cleans up pending delete projects' do
      create(:empty_project)

      expect do
        migration.up
      end.to change { Project.unscoped.count }.by(-1)
    end

    it "truncates the project's team" do
      project.add_master(admin)

      expect_any_instance_of(ProjectTeam).to receive(:truncate)

      migration.up
    end

    it 'calls Project#destroy!' do
      expect_any_instance_of(Project).to receive(:destroy!)

      migration.up
    end

    it 'does not do anything in Project#remove_pages method' do
      expect(Gitlab::PagesTransfer).not_to receive(:new)

      migration.up
    end

    context 'project not a fork of another project' do
      it "doesn't call unlink_fork" do
        expect(migration).not_to receive(:unlink_fork)

        migration.up
      end
    end

    context 'project forked from another' do
      let!(:parent_project) { create(:empty_project) }

      before do
        create(:forked_project_link, forked_to_project: project, forked_from_project: parent_project)
      end

      it 'closes open merge requests' do
        project.update_attribute(:pending_delete, false) # needed to create the MR
        merge_request = create(:merge_request, source_project: project, target_project: parent_project)
        project.update_attribute(:pending_delete, true)

        migration.up

        expect(merge_request.reload).to be_closed
      end

      it 'destroys the link' do
        migration.up

        expect(parent_project.forked_project_links).to be_empty
      end
    end
  end
end
