require 'spec_helper'
require Rails.root.join('db', 'migrate', '20180711103851_drop_duplicate_protected_tags.rb')

describe DropDuplicateProtectedTags, :migration do
  let(:project1) { create(:project) } # rubocop:disable RSpec/FactoriesInMigrationSpecs
  let(:project2) { create(:project) } # rubocop:disable RSpec/FactoriesInMigrationSpecs
  let(:protected_tags) { table(:protected_tags) }

  it 'removes duplicated protected tags' do
    protected_tags.create!(id: 1, project_id: project1.id, name: 'foo')
    protected_tags.create!(id: 2, project_id: project1.id, name: 'foo1')
    protected_tags.create!(id: 3, project_id: project1.id, name: 'foo')
    protected_tags.create!(id: 4, project_id: project2.id, name: 'foo')

    migrate!

    expect(protected_tags.all.count).to eq 3
  end

  it 'does not remove unique protected tags' do
    protected_tags.create!(id: 1, project_id: project1.id, name: 'foo1')
    protected_tags.create!(id: 2, project_id: project1.id, name: 'foo2')
    protected_tags.create!(id: 3, project_id: project1.id, name: 'foo3')

    migrate!

    expect(protected_tags.all.count).to eq 3
  end
end
