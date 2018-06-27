require 'spec_helper'

describe Gitlab::BackgroundMigration::RollbackImportStateData, :migration, schema: 20180502134117 do
  let(:migration) { described_class.new }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:import_state)  { table(:project_mirror_data) }

  before do
    namespaces.create(id: 1, name: 'gitlab-org', path: 'gitlab-org')

    projects.create!(id: 1, namespace_id: 1, name: 'gitlab1', import_url: generate(:url))
    projects.create!(id: 2, namespace_id: 1, name: 'gitlab2', path: 'gitlab2', import_url: generate(:url))

    import_state.create!(id: 1, project_id: 1, status: :started, last_error: "foo")
    import_state.create!(id: 2, project_id: 2, status: :failed)

    allow(BackgroundMigrationWorker).to receive(:perform_in)
  end

  it "creates new import_state records with project's import data" do
    migration.perform(1, 2)

    expect(projects.first.import_status).to eq("started")
    expect(projects.second.import_status).to eq("failed")
    expect(projects.first.import_error).to eq("foo")
  end
end
