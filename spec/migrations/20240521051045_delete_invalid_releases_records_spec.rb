# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe DeleteInvalidReleasesRecords, feature_category: :release_orchestration do
  let!(:releases) { table(:releases) }

  let!(:namespace) { table(:namespaces).create!(name: 'namespace', path: 'namespace') }
  let!(:user) { table(:users).create!(email: 'test@example.com', projects_limit: 10) }
  let!(:project) { table(:projects).create!(namespace_id: namespace.id, project_namespace_id: namespace.id) }

  describe '#up' do
    before do
      releases.create!(project_id: project.id, tag: 'v1', author_id: user.id, released_at: Time.current)
      releases.create!(project_id: nil, tag: 'v2', author_id: user.id, released_at: Time.current)
      releases.create!(project_id: nil, tag: 'v3', author_id: user.id, released_at: Time.current)

      stub_const("#{described_class}::BATCH_SIZE", 1)
    end

    it 'deletes records without a project_id' do
      migrate!

      expect(releases.count).to eq(1)
      expect(releases.first).to have_attributes(
        project_id: project.id,
        author_id: user.id,
        tag: 'v1'
      )
    end

    it 'does nothing on gitlab.com' do
      allow(Gitlab).to receive(:com?).and_return(true)

      migrate!

      expect(releases.count).to eq(3)
    end
  end
end
