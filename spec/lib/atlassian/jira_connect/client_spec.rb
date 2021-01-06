# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Atlassian::JiraConnect::Client do
  include StubRequests

  subject { described_class.new('https://gitlab-test.atlassian.net', 'sample_secret') }

  let_it_be(:project) { create_default(:project, :repository) }
  let_it_be(:mrs_by_title) { create_list(:merge_request, 4, :unique_branches, :jira_title) }
  let_it_be(:mrs_by_branch) { create_list(:merge_request, 2, :jira_branch) }
  let_it_be(:red_herrings) { create_list(:merge_request, 1, :unique_branches) }

  let_it_be(:pipelines) do
    (red_herrings + mrs_by_branch + mrs_by_title).map do |mr|
      create(:ci_pipeline, merge_request: mr)
    end
  end

  around do |example|
    freeze_time { example.run }
  end

  describe '.generate_update_sequence_id' do
    it 'returns monotonic_time converted it to integer' do
      allow(Gitlab::Metrics::System).to receive(:monotonic_time).and_return(1.0)

      expect(described_class.generate_update_sequence_id).to eq(1)
    end
  end

  describe '#send_info' do
    it 'calls store_deploy_info, store_build_info and store_dev_info as appropriate' do
      expect(subject).to receive(:store_build_info).with(
        project: project,
        update_sequence_id: :x,
        pipelines: :y
      ).and_return(:build_stored)

      expect(subject).to receive(:store_deploy_info).with(
        project: project,
        update_sequence_id: :x,
        deployments: :q
      ).and_return(:deploys_stored)

      expect(subject).to receive(:store_dev_info).with(
        project: project,
        update_sequence_id: :x,
        commits: :a,
        branches: :b,
        merge_requests: :c
      ).and_return(:dev_stored)

      args = {
        project: project,
        update_sequence_id: :x,
        commits: :a,
        branches: :b,
        merge_requests: :c,
        pipelines: :y,
        deployments: :q
      }

      expect(subject.send_info(**args))
        .to contain_exactly(:dev_stored, :build_stored, :deploys_stored)
    end

    it 'only calls methods that we need to call' do
      expect(subject).to receive(:store_dev_info).with(
        project: project,
        update_sequence_id: :x,
        commits: :a
      ).and_return(:dev_stored)

      args = {
        project: project,
        update_sequence_id: :x,
        commits: :a
      }

      expect(subject.send_info(**args)).to contain_exactly(:dev_stored)
    end

    it 'raises an argument error if there is nothing to send (probably a typo?)' do
      expect { subject.send_info(project: project, builds: :x) }
        .to raise_error(ArgumentError)
    end
  end

  def expected_headers(path)
    expected_jwt = Atlassian::Jwt.encode(
      Atlassian::Jwt.build_claims(Atlassian::JiraConnect.app_key, path, 'POST'),
      'sample_secret'
    )

    {
      'Authorization' => "JWT #{expected_jwt}",
      'Content-Type' => 'application/json'
    }
  end

  describe '#store_deploy_info' do
    let_it_be(:environment) { create(:environment, name: 'DEV', project: project) }
    let_it_be(:deployments) do
      pipelines.map do |p|
        build = create(:ci_build, environment: environment.name, pipeline: p, project: project)
        create(:deployment, deployable: build, environment: environment)
      end
    end

    let(:schema) do
      Atlassian::Schemata.deploy_info_payload
    end

    let(:body) do
      matcher = be_valid_json.and match_schema(schema)

      ->(text) { matcher.matches?(text) }
    end

    before do
      path = '/rest/deployments/0.1/bulk'
      stub_full_request('https://gitlab-test.atlassian.net' + path, method: :post)
        .with(body: body, headers: expected_headers(path))
    end

    it "calls the API with auth headers" do
      subject.send(:store_deploy_info, project: project, deployments: deployments)
    end

    it 'only sends information about relevant MRs' do
      expect(subject).to receive(:post).with('/rest/deployments/0.1/bulk', { deployments: have_attributes(size: 6) })

      subject.send(:store_deploy_info, project: project, deployments: deployments)
    end

    it 'does not call the API if there is nothing to report' do
      expect(subject).not_to receive(:post)

      subject.send(:store_deploy_info, project: project, deployments: deployments.take(1))
    end

    it 'does not call the API if the feature flag is not enabled' do
      stub_feature_flags(jira_sync_deployments: false)

      expect(subject).not_to receive(:post)

      subject.send(:store_deploy_info, project: project, deployments: deployments)
    end

    it 'does call the API if the feature flag enabled for the project' do
      stub_feature_flags(jira_sync_deployments: project)

      expect(subject).to receive(:post).with('/rest/deployments/0.1/bulk', { deployments: Array })

      subject.send(:store_deploy_info, project: project, deployments: deployments)
    end
  end

  describe '#store_build_info' do
    let(:build_info_payload_schema) do
      Atlassian::Schemata.build_info_payload
    end

    let(:body) do
      matcher = be_valid_json.and match_schema(build_info_payload_schema)

      ->(text) { matcher.matches?(text) }
    end

    before do
      path = '/rest/builds/0.1/bulk'
      stub_full_request('https://gitlab-test.atlassian.net' + path, method: :post)
        .with(body: body, headers: expected_headers(path))
    end

    it "calls the API with auth headers" do
      subject.send(:store_build_info, project: project, pipelines: pipelines)
    end

    it 'only sends information about relevant MRs' do
      expect(subject).to receive(:post).with('/rest/builds/0.1/bulk', { builds: have_attributes(size: 6) })

      subject.send(:store_build_info, project: project, pipelines: pipelines)
    end

    it 'does not call the API if there is nothing to report' do
      expect(subject).not_to receive(:post)

      subject.send(:store_build_info, project: project, pipelines: pipelines.take(1))
    end

    it 'does not call the API if the feature flag is not enabled' do
      stub_feature_flags(jira_sync_builds: false)

      expect(subject).not_to receive(:post)

      subject.send(:store_build_info, project: project, pipelines: pipelines)
    end

    it 'does call the API if the feature flag enabled for the project' do
      stub_feature_flags(jira_sync_builds: project)

      expect(subject).to receive(:post).with('/rest/builds/0.1/bulk', { builds: Array })

      subject.send(:store_build_info, project: project, pipelines: pipelines)
    end

    it 'avoids N+1 database queries' do
      pending 'https://gitlab.com/gitlab-org/gitlab/-/issues/292818'

      baseline = ActiveRecord::QueryRecorder.new do
        subject.send(:store_build_info, project: project, pipelines: pipelines)
      end

      pipelines << create(:ci_pipeline, head_pipeline_of: create(:merge_request, :jira_branch))

      expect { subject.send(:store_build_info, project: project, pipelines: pipelines) }.not_to exceed_query_limit(baseline)
    end
  end

  describe '#store_dev_info' do
    let_it_be(:merge_requests) { create_list(:merge_request, 2, :unique_branches) }

    before do
      path = '/rest/devinfo/0.10/bulk'

      stub_full_request('https://gitlab-test.atlassian.net' + path, method: :post)
        .with(headers: expected_headers(path))
    end

    it "calls the API with auth headers" do
      subject.send(:store_dev_info, project: project)
    end

    it 'avoids N+1 database queries' do
      control_count = ActiveRecord::QueryRecorder.new { subject.send(:store_dev_info, project: project, merge_requests: merge_requests) }.count

      merge_requests << create(:merge_request, :unique_branches)

      expect { subject.send(:store_dev_info, project: project, merge_requests: merge_requests) }.not_to exceed_query_limit(control_count)
    end
  end
end
