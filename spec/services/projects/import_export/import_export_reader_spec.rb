require 'rspec'

describe Projects::ImportExport::ImportExportReader do

  let(:test_config) { 'spec/support/import_export/import_export.yml' }
  let(:project_tree_hash) do
    {
      only: [:name, :path],
      include: [:issues, :labels,
                { merge_requests: {
                  only: [:id],
                  except: [:iid],
                  include: [:merge_request_diff, :merge_request_test]
                } },
                { commit_statuses: { include: :commit } }]
    }
  end

  it 'should generate hash from project tree config' do
    allow(described_class).to receive(:config).and_return(YAML.load_file(test_config))

    expect(described_class.project_tree).to eq(project_tree_hash)
  end
end
