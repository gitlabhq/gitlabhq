require 'spec_helper'

describe Gitlab::BackgroundMigration::PopulateImportState, :migration, schema: 20180430144643 do
  let(:migration) { described_class.new }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:import_state)  { table(:project_mirror_data) }

  before do
    namespaces.create(id: 1, name: 'gitlab-org', path: 'gitlab-org')

    projects.create!(id: 1, namespace_id: 1, name: 'gitlab1',
                     path: 'gitlab1', import_error: "foo", import_status: :started,
                     import_url: generate(:url))
    projects.create!(id: 2, namespace_id: 1, name: 'gitlab2', path: 'gitlab2',
                     import_status: :none, import_url: generate(:url))
    projects.create!(id: 3, namespace_id: 1, name: 'gitlab3',
                     path: 'gitlab3', import_error: "bar", import_status: :failed,
                     import_url: generate(:url))

    allow(BackgroundMigrationWorker).to receive(:perform_in)
  end

  it "creates new import_state records with project's import data" do
    expect(projects.where.not(import_status: :none).count).to eq(2)

    expect do
      migration.perform(1, 3)
    end.to change { import_state.all.count }.from(0).to(2)

    expect(import_state.first.last_error).to eq("foo")
    expect(import_state.last.last_error).to eq("bar")
    expect(import_state.first.status).to eq("started")
    expect(import_state.last.status).to eq("failed")
    expect(projects.first.import_status).to eq("none")
    expect(projects.last.import_status).to eq("none")
  end
end
