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

  describe '.generate_update_sequence_id' do
    it 'returns unix time in microseconds as integer', :aggregate_failures do
      travel_to(Time.utc(1970, 1, 1, 0, 0, 1)) do
        expect(described_class.generate_update_sequence_id).to eq(1000)
      end

      travel_to(Time.utc(1970, 1, 1, 0, 0, 5)) do
        expect(described_class.generate_update_sequence_id).to eq(5000)
      end
    end
  end

  describe '#send_info' do
    it 'calls more specific methods as appropriate' do
      expect(subject).to receive(:store_ff_info).with(
        project: project,
        update_sequence_id: :x,
        feature_flags: :r
      ).and_return(:ff_stored)

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
        deployments: :q,
        feature_flags: :r
      }

      expect(subject.send_info(**args))
        .to contain_exactly(:dev_stored, :build_stored, :deploys_stored, :ff_stored)
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

  describe '#handle_response' do
    let(:errors) { [{ 'message' => 'X' }, { 'message' => 'Y' }] }
    let(:processed) { subject.send(:handle_response, response, 'foo') { |x| [:data, x] } }

    context 'the response is 200 OK' do
      let(:response) { double(code: 200, parsed_response: :foo) }

      it 'yields to the block' do
        expect(processed).to eq [:data, :foo]
      end
    end

    context 'the response is 400 bad request' do
      let(:response) { double(code: 400, parsed_response: errors) }

      it 'extracts the errors messages' do
        expect(processed).to eq('errorMessages' => %w(X Y))
      end
    end

    context 'the response is 401 forbidden' do
      let(:response) { double(code: 401, parsed_response: nil) }

      it 'reports that our JWT is wrong' do
        expect(processed).to eq('errorMessages' => ['Invalid JWT'])
      end
    end

    context 'the response is 403' do
      let(:response) { double(code: 403, parsed_response: nil) }

      it 'reports that the App is misconfigured' do
        expect(processed).to eq('errorMessages' => ['App does not support foo'])
      end
    end

    context 'the response is 413' do
      let(:response) { double(code: 413, parsed_response: errors) }

      it 'extracts the errors messages' do
        expect(processed).to eq('errorMessages' => ['Data too large', 'X', 'Y'])
      end
    end

    context 'the response is 429' do
      let(:response) { double(code: 429, parsed_response: nil) }

      it 'reports that we exceeded the rate limit' do
        expect(processed).to eq('errorMessages' => ['Rate limit exceeded'])
      end
    end

    context 'the response is 503' do
      let(:response) { double(code: 503, parsed_response: nil) }

      it 'reports that the service is unavailable' do
        expect(processed).to eq('errorMessages' => ['Service unavailable'])
      end
    end

    context 'the response is anything else' do
      let(:response) { double(code: 1000, parsed_response: :something) }

      it 'reports that this was unanticipated' do
        expect(processed).to eq('errorMessages' => ['Unknown error'], 'response' => :something)
      end
    end
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

    let(:rejections) { [] }
    let(:response_body) do
      {
        acceptedDeployments: [],
        rejectedDeployments: rejections,
        unknownIssueKeys: []
      }.to_json
    end

    before do
      path = '/rest/deployments/0.1/bulk'
      stub_full_request('https://gitlab-test.atlassian.net' + path, method: :post)
        .with(body: body, headers: expected_headers(path))
        .to_return(body: response_body, headers: { 'Content-Type': 'application/json' })
    end

    it "calls the API with auth headers" do
      subject.send(:store_deploy_info, project: project, deployments: deployments)
    end

    it 'only sends information about relevant MRs' do
      expect(subject).to receive(:post).with('/rest/deployments/0.1/bulk', { deployments: have_attributes(size: 6) }).and_call_original

      subject.send(:store_deploy_info, project: project, deployments: deployments)
    end

    it 'does not call the API if there is nothing to report' do
      expect(subject).not_to receive(:post)

      subject.send(:store_deploy_info, project: project, deployments: deployments.take(1))
    end

    context 'there are errors' do
      let(:rejections) do
        [{ errors: [{ message: 'X' }, { message: 'Y' }] }, { errors: [{ message: 'Z' }] }]
      end

      it 'reports the errors' do
        response = subject.send(:store_deploy_info, project: project, deployments: deployments)

        expect(response['errorMessages']).to eq(%w(X Y Z))
      end
    end
  end

  describe '#store_ff_info' do
    let_it_be(:feature_flags) { create_list(:operations_feature_flag, 3, project: project) }

    let(:schema) do
      Atlassian::Schemata.ff_info_payload
    end

    let(:body) do
      matcher = be_valid_json.and match_schema(schema)

      ->(text) { matcher.matches?(text) }
    end

    let(:failures) { {} }
    let(:response_body) do
      {
        acceptedFeatureFlags: [],
        failedFeatureFlags: failures,
        unknownIssueKeys: []
      }.to_json
    end

    before do
      feature_flags.first.update!(description: 'RELEVANT-123')
      feature_flags.second.update!(description: 'RELEVANT-123')
      path = '/rest/featureflags/0.1/bulk'
      stub_full_request('https://gitlab-test.atlassian.net' + path, method: :post)
        .with(body: body, headers: expected_headers(path))
        .to_return(body: response_body, headers: { 'Content-Type': 'application/json' })
    end

    it "calls the API with auth headers" do
      subject.send(:store_ff_info, project: project, feature_flags: feature_flags)
    end

    it 'only sends information about relevant MRs' do
      expect(subject).to receive(:post).with('/rest/featureflags/0.1/bulk', {
        flags: have_attributes(size: 2), properties: Hash
      }).and_call_original

      subject.send(:store_ff_info, project: project, feature_flags: feature_flags)
    end

    it 'does not call the API if there is nothing to report' do
      expect(subject).not_to receive(:post)

      subject.send(:store_ff_info, project: project, feature_flags: [feature_flags.last])
    end

    context 'there are errors' do
      let(:failures) do
        {
          a: [{ message: 'X' }, { message: 'Y' }],
          b: [{ message: 'Z' }]
        }
      end

      it 'reports the errors' do
        response = subject.send(:store_ff_info, project: project, feature_flags: feature_flags)

        expect(response['errorMessages']).to eq(['a: X', 'a: Y', 'b: Z'])
      end
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

    let(:failures) { [] }
    let(:response_body) do
      {
        acceptedBuilds: [],
        rejectedBuilds: failures,
        unknownIssueKeys: []
      }.to_json
    end

    before do
      path = '/rest/builds/0.1/bulk'
      stub_full_request('https://gitlab-test.atlassian.net' + path, method: :post)
        .with(body: body, headers: expected_headers(path))
        .to_return(body: response_body, headers: { 'Content-Type': 'application/json' })
    end

    it "calls the API with auth headers" do
      subject.send(:store_build_info, project: project, pipelines: pipelines)
    end

    it 'only sends information about relevant MRs' do
      expect(subject).to receive(:post)
        .with('/rest/builds/0.1/bulk', { builds: have_attributes(size: 6) })
        .and_call_original

      subject.send(:store_build_info, project: project, pipelines: pipelines)
    end

    it 'does not call the API if there is nothing to report' do
      expect(subject).not_to receive(:post)

      subject.send(:store_build_info, project: project, pipelines: pipelines.take(1))
    end

    context 'there are errors' do
      let(:failures) do
        [{ errors: [{ message: 'X' }, { message: 'Y' }] }, { errors: [{ message: 'Z' }] }]
      end

      it 'reports the errors' do
        response = subject.send(:store_build_info, project: project, pipelines: pipelines)

        expect(response['errorMessages']).to eq(%w(X Y Z))
      end
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
