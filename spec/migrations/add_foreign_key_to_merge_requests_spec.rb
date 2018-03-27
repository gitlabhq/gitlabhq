require 'spec_helper'
require Rails.root.join('db', 'migrate', '20170713104829_add_foreign_key_to_merge_requests.rb')

describe AddForeignKeyToMergeRequests, :migration do
  let(:projects) { table(:projects) }
  let(:merge_requests) { table(:merge_requests) }
  let(:pipelines) { table(:ci_pipelines) }

  before do
    projects.create!(name: 'gitlab', path: 'gitlab-org/gitlab-ce')
    pipelines.create!(project_id: projects.first.id,
                      ref: 'some-branch',
                      sha: 'abc12345')

    # merge request without a pipeline
    create_merge_request(head_pipeline_id: nil)

    # merge request with non-existent pipeline
    create_merge_request(head_pipeline_id: 1234)

    # merge reqeust with existing pipeline assigned
    create_merge_request(head_pipeline_id: pipelines.first.id)
  end

  it 'correctly adds a foreign key to head_pipeline_id' do
    migrate!

    expect(merge_requests.first.head_pipeline_id).to be_nil
    expect(merge_requests.second.head_pipeline_id).to be_nil
    expect(merge_requests.third.head_pipeline_id).to eq pipelines.first.id
  end

  def create_merge_request(**opts)
    merge_requests.create!(source_project_id: projects.first.id,
                           target_project_id: projects.first.id,
                           source_branch: 'some-branch',
                           target_branch: 'master', **opts)
  end
end
