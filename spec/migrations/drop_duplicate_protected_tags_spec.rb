require 'spec_helper'
require Rails.root.join('db', 'migrate', '20180711103851_drop_duplicate_protected_tags.rb')

describe DropDuplicateProtectedTags, :migration do
  let(:project1) { create(:project) } # rubocop:disable RSpec/FactoriesInMigrationSpecs
  let(:project2) { create(:project) } # rubocop:disable RSpec/FactoriesInMigrationSpecs
  let(:protected_tags) { table(:protected_tags) }

  before do
    stub_const("#{described_class}::BATCH_SIZE", 1)
  end

  it 'removes duplicated protected tags' do
    tag1 = protected_tags.create!(id: 1, project_id: project1.id, name: 'foo')
    tag2 = protected_tags.create!(id: 2, project_id: project1.id, name: 'foo1')
    tag3 = protected_tags.create!(id: 3, project_id: project1.id, name: 'foo')
    tag4 = protected_tags.create!(id: 4, project_id: project1.id, name: 'foo')
    tag5 = protected_tags.create!(id: 5, project_id: project2.id, name: 'foo')

    migrate!

    expect(protected_tags.all.count).to eq 3
    expect(protected_tags.find_by(id: tag1.id)).to be_nil
    expect(protected_tags.find_by(id: tag2.id)).not_to be_nil
    expect(protected_tags.find_by(id: tag3.id)).to be_nil
    expect(protected_tags.find_by(id: tag4.id)).not_to be_nil
    expect(protected_tags.find_by(id: tag5.id)).not_to be_nil
  end

  it 'does not remove unique protected tags' do
    protected_tags.create!(id: 1, project_id: project1.id, name: 'foo1')
    protected_tags.create!(id: 2, project_id: project1.id, name: 'foo2')
    protected_tags.create!(id: 3, project_id: project1.id, name: 'foo3')

    migrate!

    expect(protected_tags.all.count).to eq 3
  end
end
