# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe DeleteInvalidRemoteMirrorsRecords, feature_category: :source_code_management do
  let!(:remote_mirrors) { table(:remote_mirrors) }

  let!(:namespace) { table(:namespaces).create!(name: 'namespace', path: 'namespace') }
  let!(:project) { table(:projects).create!(namespace_id: namespace.id, project_namespace_id: namespace.id) }

  describe '#up' do
    before do
      remote_mirrors.create!(project_id: project.id, url: 'http://example.com')
      remote_mirrors.create!(project_id: nil, url: 'http://example2.com')
      remote_mirrors.create!(project_id: nil, url: 'http://example3.com')

      stub_const("#{described_class}::BATCH_SIZE", 1)
    end

    it 'deletes records without a project_id' do
      migrate!

      expect(remote_mirrors.count).to eq(1)
      expect(remote_mirrors.first).to have_attributes(
        project_id: project.id,
        url: 'http://example.com'
      )
    end

    it 'does nothing on gitlab.com' do
      allow(Gitlab).to receive(:com?).and_return(true)

      migrate!

      expect(remote_mirrors.count).to eq(3)
    end
  end
end
