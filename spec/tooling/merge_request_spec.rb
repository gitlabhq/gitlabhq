# frozen_string_literal: true

require 'webmock/rspec'

require_relative '../../tooling/merge_request'
require_relative '../support/helpers/next_instance_of'

RSpec.describe Tooling::MergeRequest do
  let(:project_path) { 'gitlab-org/gitlab' }
  let(:branch_name) { 'my-branch' }
  let(:merge_request_iid) { 123 }
  let(:merge_requests) { [{ 'iid' => merge_request_iid }] }

  describe '.for' do
    let(:stub_api) do
      stub_request(:get, "https://gitlab.com/api/v4/projects/gitlab-org%2Fgitlab/merge_requests")
        .and_return(body: merge_requests)
    end

    before do
      stub_api.with(query: { source_branch: branch_name, order_by: 'updated_at', sort: 'desc' })
    end

    it 'fetches merge request for local branch in the given GitLab project path' do
      merge_request = described_class.for(branch: branch_name, project_path: project_path)

      expect(merge_request.iid).to eq(merge_request_iid)
      expect(stub_api).to have_been_requested.once
    end
  end
end
