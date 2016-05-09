require 'spec_helper'

describe Gitlab::ImportExport::ImportExportReader do

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
    expect(described_class.new(config: test_config).project_tree) =~ (project_tree_hash)
  end
end
