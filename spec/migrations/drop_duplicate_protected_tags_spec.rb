require 'spec_helper'
require Rails.root.join('db', 'migrate', '20180711103851_drop_duplicate_protected_tags.rb')

describe DropDuplicateProtectedTags, :migration do
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:protected_tags) { table(:protected_tags) }

  before do
    stub_const("#{described_class}::BATCH_SIZE", 2)

    namespaces.create(id: 1, name: 'gitlab-org', path: 'gitlab-org')
    projects.create!(id: 1, namespace_id: 1, name: 'gitlab1', path: 'gitlab1')
    projects.create!(id: 2, namespace_id: 1, name: 'gitlab2', path: 'gitlab2')
  end

  it 'removes duplicated protected tags' do
    protected_tags.create!(id: 1, project_id: 1, name: 'foo')
    tag2 = protected_tags.create!(id: 2, project_id: 1, name: 'foo1')
    protected_tags.create!(id: 3, project_id: 1, name: 'foo')
    tag4 = protected_tags.create!(id: 4, project_id: 1, name: 'foo')
    tag5 = protected_tags.create!(id: 5, project_id: 2, name: 'foo')

    migrate!

    expect(protected_tags.all.count).to eq 3
    expect(protected_tags.all.pluck(:id)).to contain_exactly(tag2.id, tag4.id, tag5.id)
  end

  it 'does not remove unique protected tags' do
    tag1 = protected_tags.create!(id: 1, project_id: 1, name: 'foo1')
    tag2 = protected_tags.create!(id: 2, project_id: 1, name: 'foo2')
    tag3 = protected_tags.create!(id: 3, project_id: 1, name: 'foo3')

    migrate!

    expect(protected_tags.all.count).to eq 3
    expect(protected_tags.all.pluck(:id)).to contain_exactly(tag1.id, tag2.id, tag3.id)
  end
end
