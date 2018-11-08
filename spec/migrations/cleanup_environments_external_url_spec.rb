require 'spec_helper'
require Rails.root.join('db', 'migrate', '20181108091549_cleanup_environments_external_url.rb')

describe CleanupEnvironmentsExternalUrl, :migration do
  let(:environments)    { table(:environments) }
  let(:invalid_entries) { environments.where(environments.arel_table[:external_url].matches('javascript://%')) }
  let(:namespaces)      { table(:namespaces) }
  let(:projects)        { table(:projects) }

  before do
    namespace = namespaces.create(name: 'foo', path: 'foo')
    project = projects.create!(namespace_id: namespace.id)

    environments.create!(id: 1, project_id: project.id, name: 'poisoned', slug: 'poisoned', external_url: 'javascript://alert("1")')
  end

  it 'clears every environment with a javascript external_url' do
    expect do
      subject.up
    end.to change { invalid_entries.count }.from(1).to(0)
  end

  it 'do not removes environments' do
    expect do
      subject.up
    end.not_to change { environments.count }
  end
end
