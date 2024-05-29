# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe DeleteInvalidPathLocksRecords, feature_category: :source_code_management do
  let!(:path_locks) { table(:path_locks) }

  let!(:namespace) { table(:namespaces).create!(name: 'namespace', path: 'namespace') }
  let!(:user) { table(:users).create!(email: 'test@example.com', projects_limit: 10) }
  let!(:project) { table(:projects).create!(namespace_id: namespace.id, project_namespace_id: namespace.id) }

  describe '#up' do
    before do
      path_locks.create!(project_id: project.id, user_id: user.id, path: 'path1')
      path_locks.create!(project_id: nil, user_id: user.id, path: 'path2')
      path_locks.create!(project_id: nil, user_id: user.id, path: 'path3')

      stub_const("#{described_class}::BATCH_SIZE", 1)
    end

    it 'deletes records without a project_id' do
      migrate!

      expect(path_locks.count).to eq(1)
      expect(path_locks.first).to have_attributes(
        project_id: project.id,
        user_id: user.id,
        path: 'path1'
      )
    end

    it 'does nothing on gitlab.com' do
      allow(Gitlab).to receive(:com?).and_return(true)

      migrate!

      expect(path_locks.count).to eq(3)
    end
  end
end
