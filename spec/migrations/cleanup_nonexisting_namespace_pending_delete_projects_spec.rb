require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20170816102555_cleanup_nonexisting_namespace_pending_delete_projects.rb')

describe CleanupNonexistingNamespacePendingDeleteProjects do
  before do
    # Stub after_save callbacks that will fail when Project has invalid namespace
    allow_any_instance_of(Project).to receive(:ensure_storage_path_exist).and_return(nil)
    allow_any_instance_of(Project).to receive(:update_project_statistics).and_return(nil)
  end

  describe '#up' do
    set(:some_project) { create(:project) }

    it 'only cleans up when namespace does not exist' do
      create(:project, pending_delete: true)
      project = build(:project, pending_delete: true, namespace: nil, namespace_id: Namespace.maximum(:id).to_i.succ)
      project.save(validate: false)

      expect(NamespacelessProjectDestroyWorker).to receive(:bulk_perform_async).with([[project.id]])

      described_class.new.up
    end

    it 'does nothing when no pending delete projects without namespace found' do
      create(:project, pending_delete: true, namespace: create(:namespace))

      expect(NamespacelessProjectDestroyWorker).not_to receive(:bulk_perform_async)

      described_class.new.up
    end
  end
end
