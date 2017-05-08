require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20170502101023_cleanup_namespaceless_pending_delete_projects.rb')

describe CleanupNamespacelessPendingDeleteProjects do
  before do
    # Stub after_save callbacks that will fail when Project has no namespace
    allow_any_instance_of(Project).to receive(:ensure_dir_exist).and_return(nil)
    allow_any_instance_of(Project).to receive(:update_project_statistics).and_return(nil)
  end

  describe '#up' do
    it 'only cleans up pending delete projects' do
      admin = create(:admin)
      create(:empty_project)
      create(:empty_project, pending_delete: true)
      project = build(:empty_project, pending_delete: true, namespace_id: nil)
      project.save(validate: false)

      expect(NamespacelessProjectDestroyWorker).to receive(:bulk_perform_async).with([[project.id.to_s, admin.id, {}]])

      described_class.new.up
    end
  end
end
