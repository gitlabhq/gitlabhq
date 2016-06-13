require 'spec_helper'

describe Gitlab::ImportExport::Reader, lib: true  do
  let(:shared) { Gitlab::ImportExport::Shared.new(relative_path:'') }
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

  before do
    allow_any_instance_of(Gitlab::ImportExport).to receive(:config_file).and_return(test_config)
  end

  it 'generates hash from project tree config' do
    expect(described_class.new(shared: shared).project_tree).to match(project_tree_hash)
  end
end
