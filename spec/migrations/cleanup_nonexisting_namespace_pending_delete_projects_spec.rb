require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20170816102555_cleanup_nonexisting_namespace_pending_delete_projects.rb')

describe CleanupNonexistingNamespacePendingDeleteProjects, :migration do
  let(:projects) { table(:projects) }
  let(:namespaces) { table(:namespaces) }

  describe '#up' do
    let!(:some_project) { projects.create! }
    let(:namespace) { namespaces.create!(name: 'test', path: 'test') }

    it 'only cleans up when namespace does not exist' do
      projects.create!(pending_delete: true, namespace_id: namespace.id)
      project = projects.create!(pending_delete: true, namespace_id: 0)

      expect(NamespacelessProjectDestroyWorker).to receive(:bulk_perform_async).with([[project.id]])

      described_class.new.up
    end

    it 'does nothing when no pending delete projects without namespace found' do
      projects.create!(pending_delete: true, namespace_id: namespace.id)

      expect(NamespacelessProjectDestroyWorker).not_to receive(:bulk_perform_async)

      described_class.new.up
    end
  end
end
