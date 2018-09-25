# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20180809195358_migrate_null_wiki_access_levels.rb')

describe MigrateNullWikiAccessLevels, :migration do
  let(:namespaces) { table('namespaces') }
  let(:projects) { table(:projects) }
  let(:project_features) { table(:project_features) }
  let(:migration) { described_class.new }

  before do
    namespace = namespaces.create(name: 'foo', path: 'foo')

    projects.create!(id: 1, name: 'gitlab1', path: 'gitlab1', namespace_id: namespace.id)
    projects.create!(id: 2, name: 'gitlab2', path: 'gitlab2', namespace_id: namespace.id)
    projects.create!(id: 3, name: 'gitlab3', path: 'gitlab3', namespace_id: namespace.id)

    project_features.create!(id: 1, project_id: 1, wiki_access_level: nil)
    project_features.create!(id: 2, project_id: 2, wiki_access_level: 10)
    project_features.create!(id: 3, project_id: 3, wiki_access_level: 20)
  end

  describe '#up' do
    it 'migrates existing project_features with wiki_access_level NULL to 20' do
      expect { migration.up }.to change { project_features.where(wiki_access_level: 20).count }.by(1)
    end
  end
end
