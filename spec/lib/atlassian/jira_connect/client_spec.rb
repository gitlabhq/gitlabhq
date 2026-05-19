# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Atlassian::JiraConnect::Client, feature_category: :integrations do
  include StubRequests

  subject(:client) { described_class.new('https://gitlab-test.atlassian.net', 'sample_secret') }

  let_it_be(:project) { create_default(:project, :repository) }
  let_it_be(:mrs_by_title) { create_list(:merge_request, 4, :unique_branches, :jira_title) }
  let_it_be(:mrs_by_branch) { create_list(:merge_request, 2, :jira_branch) }
  let_it_be(:red_herrings) { create_list(:merge_request, 1, :unique_branches) }
  let_it_be(:mrs_by_description) { create_list(:merge_request, 2, :unique_branches, :jira_description) }

  let_it_be(:pipelines) do
    (red_herrings + mrs_by_branch + mrs_by_title + mrs_by_description).map do |mr|
      create(:ci_pipeline, merge_request: mr)
    end
  end

  around do |example|
    if example.metadata[:skip_freeze_time]
      example.run
    else
      freeze_time { example.run }
    end
  end

  describe '.generate_update_sequence_id', :skip_freeze_time do
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

      expect(subject).to receive(:remove_branch_info).with(
        project: project,
        update_sequence_id: :x,
        remove_branch_info: :j
      ).and_return(:branch_removed)

      args = {
        project: project,
        update_sequence_id: :x,
        commits: :a,
        branches: :b,
        merge_requests: :c,
        pipelines: :y,
        deployments: :q,
        feature_flags: :r,
        remove_branch_info: :j
      }

      expect(subject.send_info(**args))
        .to contain_exactly(:dev_stored, :build_stored, :deploys_stored, :ff_stored, :branch_removed)
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

  def expected_headers(path, method)
    expected_jwt = Atlassian::Jwt.encode(
      Atlassian::Jwt.build_claims(Atlassian::JiraConnect.app_key, path, method),
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

    before do
      allow(subject).to receive(:parse_jira_error_messages).and_call_original
    end

    context 'when the response is 200 OK' do
      let(:response) { double(code: 200, parsed_response: :foo) }

      it 'yields to the block' do
        expect(processed).to eq [:data, :foo]
      end
    end

    context 'when the response is 202 accepted' do
      let(:response) { double(code: 202, parsed_response: :foo) }

      it 'yields to the block' do
        expect(processed).to eq [:data, :foo]
      end
    end

    context 'when the response is 400 bad request' do
      let(:response) { double(code: 400, parsed_response: errors) }

      it 'extracts the errors messages' do
        expect(subject).to receive(:parse_jira_error_messages).with(errors).and_return(%w[X Y])
        expect(processed).to eq('errorMessages' => %w[X Y], 'responseCode' => 400)
      end
    end

    context 'when the response is 401 forbidden' do
      let(:response) { double(code: 401, parsed_response: nil) }

      it 'reports that our JWT is wrong' do
        expect(processed).to eq('errorMessages' => ['Invalid JWT'], 'responseCode' => 401)
      end
    end

    context 'when the response is 403' do
      let(:response) { double(code: 403, parsed_response: nil) }

      it 'reports that the App is misconfigured' do
        expect(processed).to eq('errorMessages' => ['App does not support foo'], 'responseCode' => 403)
      end
    end

    context 'when the response is 413' do
      let(:response) { double(code: 413, parsed_response: errors) }

      it 'extracts the errors messages' do
        expect(subject).to receive(:parse_jira_error_messages).with(errors).and_return(%w[X Y])
        expect(processed).to eq('errorMessages' => ['Data too large', 'X', 'Y'], 'responseCode' => 413)
      end
    end

    context 'when the response is 429' do
      let(:response) { double(code: 429, parsed_response: nil) }

      it 'reports that we exceeded the rate limit' do
        expect(processed).to eq('errorMessages' => ['Rate limit exceeded'], 'responseCode' => 429)
      end
    end

    context 'when the response is 503' do
      let(:response) { double(code: 503, parsed_response: nil) }

      it 'reports that the service is unavailable' do
        expect(processed).to eq('errorMessages' => ['Service unavailable'], 'responseCode' => 503)
      end
    end

    context 'when the response is anything else' do
      let(:response) { double(code: 1000, parsed_response: :something) }

      it 'reports that this was unanticipated' do
        expect(processed).to eq('errorMessages' => ['Unknown error'], 'responseCode' => 1000, 'response' => :something)
      end
    end
  end

  describe '#request_body_schema' do
    let(:response) { instance_double(HTTParty::Response, success?: true, code: 200, request: request) }

    context 'with valid JSON request body' do
      let(:request) { instance_double(HTTParty::Request, raw_body: '{ "foo": 1, "bar": 2 }') }

      it 'returns the request body' do
        expect(subject.send(:request_body_schema, response)).to eq({ "foo" => 1, "bar" => 2 })
      end
    end

    context 'with invalid JSON request body' do
      let(:request) { instance_double(HTTParty::Request, raw_body: 'invalid json') }

      it 'reports the invalid json' do
        expect(subject.send(:request_body_schema, response)).to eq('Request body includes invalid JSON')
      end
    end
  end

  describe '#store_deploy_info' do
    let_it_be(:deployments) { create_list(:deployment, 1) }

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
      stub_full_request("https://gitlab-test.atlassian.net#{path}", method: :post)
        .with(body: body, headers: expected_headers(path, 'POST'))
        .to_return(body: response_body, headers: { 'Content-Type': 'application/json' })
    end

    it "calls the API with auth headers" do
      subject.send(:store_deploy_info, project: project, deployments: deployments)
    end

    it 'calls the API if issue keys are found' do
      expect(subject).to receive(:post).with(
        '/rest/deployments/0.1/bulk', { deployments: have_attributes(size: 1) }
      ).and_call_original

      subject.send(:store_deploy_info, project: project, deployments: deployments)
    end

    it 'calls the API if no issue keys are found, but there are service IDs' do
      allow_next_instances_of(Atlassian::JiraConnect::Serializers::DeploymentEntity, nil) do |entity|
        allow(entity).to receive(:issue_keys).and_return([])
        allow(entity).to receive(:service_ids_from_integration_configuration).and_return([{ associationType: 'serviceIdOrKeys', values: ['foo'] }])
      end

      expect(subject).to receive(:post).with(
        '/rest/deployments/0.1/bulk', { deployments: have_attributes(size: 1) }
      ).and_call_original

      subject.send(:store_deploy_info, project: project, deployments: deployments)
    end

    it 'does not call the API if no issue keys or service IDs are found' do
      allow_next_instances_of(Atlassian::JiraConnect::Serializers::DeploymentEntity, nil) do |entity|
        allow(entity).to receive(:issue_keys).and_return([])
        allow(entity).to receive(:service_ids_from_integration_configuration).and_return([])
      end

      expect(subject).not_to receive(:post)
    end

    context 'when there are errors' do
      let(:rejections) do
        [{ errors: [{ message: 'X' }, { message: 'Y' }] }, { errors: [{ message: 'Z' }] }]
      end

      it 'reports the errors' do
        response = subject.send(:store_deploy_info, project: project, deployments: deployments)

        expect(response['errorMessages']).to eq(%w[X Y Z])
        expect(response['responseCode']).to eq(200)
        expect(response['requestBody']).to be_a(Hash)
      end
    end

    context 'when deployment has more than 500 total association values' do
      let(:issue_keys) { (1..600).map { |i| "JIRA-#{i}" } }
      let(:success_response) do
        double(code: 202,
          parsed_response: { 'acceptedDeployments' => [], 'rejectedDeployments' => [], 'unknownIssueKeys' => [] },
          request: double(raw_body: '{}'))
      end

      before do
        allow_next_instances_of(Atlassian::JiraConnect::Serializers::DeploymentEntity, nil) do |entity|
          allow(entity).to receive(:issue_keys).and_return(issue_keys)
          allow(entity).to receive(:service_ids_from_integration_configuration).and_return([])
        end

        allow(subject).to receive(:post).and_return(success_response)
      end

      context 'when truncate_jira_deployment_associations is enabled' do
        before do
          stub_feature_flags(truncate_jira_deployment_associations: true)
        end

        it 'makes a single API request with at most the limit of association values' do
          subject.send(:store_deploy_info, project: project, deployments: deployments)

          expect(subject).to have_received(:post).once do |_path, payload|
            deployment = payload[:deployments].first
            total = (deployment[:associations] || []).sum { |a| a[:values]&.size || 0 }
            expect(total).to eq(Atlassian::JiraConnect::Client::ASSOCIATION_VALUES_LIMIT)
          end
        end
      end

      context 'when truncate_jira_deployment_associations is disabled' do
        before do
          stub_feature_flags(truncate_jira_deployment_associations: false)
        end

        it 'sends the full payload without truncation' do
          subject.send(:store_deploy_info, project: project, deployments: deployments)

          expect(subject).to have_received(:post).once do |_path, payload|
            deployment = payload[:deployments].first
            total = (deployment[:associations] || []).sum { |a| a[:values]&.size || 0 }
            expect(total).to be > Atlassian::JiraConnect::Client::ASSOCIATION_VALUES_LIMIT
          end
        end

        it 'does not track a truncation exception' do
          expect(Gitlab::ErrorTracking).not_to receive(:track_exception).with(
            instance_of(Atlassian::JiraConnect::Client::AssociationsTruncatedError),
            anything
          )

          subject.send(:store_deploy_info, project: project, deployments: deployments)
        end
      end
    end

    context 'when deployment has 500 or fewer total association values' do
      let(:issue_keys) { (1..100).map { |i| "JIRA-#{i}" } }

      before do
        allow_next_instances_of(Atlassian::JiraConnect::Serializers::DeploymentEntity, nil) do |entity|
          allow(entity).to receive(:issue_keys).and_return(issue_keys)
          allow(entity).to receive(:service_ids_from_integration_configuration).and_return([])
        end
      end

      it 'makes a single API request' do
        allow(subject).to receive(:post).and_return(
          double(code: 202,
            parsed_response: { 'acceptedDeployments' => [], 'rejectedDeployments' => [], 'unknownIssueKeys' => [] },
            request: double(raw_body: '{}'))
        )

        subject.send(:store_deploy_info, project: project, deployments: deployments)

        expect(subject).to have_received(:post).once
      end

      it 'does not track a truncation exception' do
        allow(subject).to receive(:post).and_return(
          double(code: 202,
            parsed_response: { 'acceptedDeployments' => [], 'rejectedDeployments' => [], 'unknownIssueKeys' => [] },
            request: double(raw_body: '{}'))
        )

        expect(Gitlab::ErrorTracking).not_to receive(:track_exception).with(
          instance_of(Atlassian::JiraConnect::Client::AssociationsTruncatedError),
          anything
        )

        subject.send(:store_deploy_info, project: project, deployments: deployments)
      end
    end
  end

  describe '#truncate_associations_if_needed' do
    subject(:client) { described_class.new('https://gitlab-test.atlassian.net', 'sample_secret') }

    context 'when total values are within the limit' do
      let(:deployment_hash) do
        {
          associations: [
            { associationType: :issueKeys, values: %w[JIRA-1 JIRA-2] },
            { associationType: :commit, values: [{ commitHash: 'abc', repositoryId: '1' }] }
          ],
          deploymentSequenceNumber: 1
        }
      end

      it 'returns the deployment unchanged' do
        expect(client.send(:truncate_associations_if_needed, deployment_hash)).to eq(deployment_hash)
      end

      it 'does not track an exception' do
        expect(Gitlab::ErrorTracking).not_to receive(:track_exception)

        client.send(:truncate_associations_if_needed, deployment_hash)
      end
    end

    context 'when associations are absent' do
      let(:deployment_hash) { { deploymentSequenceNumber: 1 } }

      it 'returns the deployment unchanged' do
        expect(client.send(:truncate_associations_if_needed, deployment_hash)).to eq(deployment_hash)
      end
    end

    context 'when an association has nil values' do
      let(:deployment_hash) do
        {
          associations: [
            { associationType: :issueKeys, values: %w[JIRA-1 JIRA-2] },
            { associationType: :commit, values: nil }
          ],
          deploymentSequenceNumber: 1
        }
      end

      it 'treats nil values as zero and returns the deployment unchanged' do
        expect(client.send(:truncate_associations_if_needed, deployment_hash)).to eq(deployment_hash)
      end
    end

    context 'when total values are exactly at the limit' do
      let(:deployment_hash) do
        {
          associations: [
            { associationType: :issueKeys, values: (1..500).map { |i| "JIRA-#{i}" } }
          ],
          deploymentSequenceNumber: 1
        }
      end

      it 'returns the deployment unchanged' do
        expect(client.send(:truncate_associations_if_needed, deployment_hash)).to eq(deployment_hash)
      end
    end

    context 'when total values exceed the limit' do
      let(:issue_keys) { (1..700).map { |i| "JIRA-#{i}" } }
      let(:deployment_hash) do
        {
          associations: [
            { associationType: :issueKeys, values: issue_keys }
          ],
          deploymentSequenceNumber: 1,
          pipeline: { id: 'pipeline-9' }
        }
      end

      it 'truncates to the limit preserving the first values' do
        result = client.send(:truncate_associations_if_needed, deployment_hash)

        expect(result[:associations].sum { |a| a[:values].size }).to eq(500)
        expect(result[:associations].first[:values]).to eq(issue_keys.first(500))
      end

      it 'preserves the deployment metadata' do
        result = client.send(:truncate_associations_if_needed, deployment_hash)

        expect(result[:deploymentSequenceNumber]).to eq(1)
        expect(result[:pipeline]).to eq({ id: 'pipeline-9' })
      end

      it 'tracks an exception with the dropped count and Sentry tags' do
        expect(Gitlab::ErrorTracking).to receive(:track_exception).with(
          instance_of(Atlassian::JiraConnect::Client::AssociationsTruncatedError),
          extra: {
            deployment_sequence_number: 1,
            pipeline_id: 'pipeline-9',
            total_values: 700,
            dropped_values: 200
          },
          tags: { dropped_bucket: '100-499', truncation_severity: 'normal' }
        )

        client.send(:truncate_associations_if_needed, deployment_hash)
      end
    end

    context 'when bucketing dropped values into Sentry tags' do
      using RSpec::Parameterized::TableSyntax

      where(:dropped, :expected_bucket, :expected_severity) do
        1    | '<100'    | 'normal'
        99   | '<100'    | 'normal'
        100  | '100-499' | 'normal'
        499  | '100-499' | 'normal'
        500  | '500-999' | 'normal'
        799  | '500-999' | 'normal'
        800  | '500-999' | 'high'
        999  | '500-999' | 'high'
        1000 | '>=1000'  | 'high'
        1500 | '>=1000'  | 'high'
      end

      with_them do
        let(:deployment_hash) do
          {
            associations: [
              { associationType: :issueKeys, values: (1..(500 + dropped)).map { |i| "JIRA-#{i}" } }
            ],
            deploymentSequenceNumber: 1
          }
        end

        it 'maps dropped count to the expected tags' do
          expect(Gitlab::ErrorTracking).to receive(:track_exception).with(
            instance_of(Atlassian::JiraConnect::Client::AssociationsTruncatedError),
            hash_including(tags: { dropped_bucket: expected_bucket, truncation_severity: expected_severity })
          )

          client.send(:truncate_associations_if_needed, deployment_hash)
        end
      end
    end

    context 'with mixed association types' do
      let(:issue_keys) { (1..400).map { |i| "JIRA-#{i}" } }
      let(:commits) { (1..200).map { |i| { commitHash: "sha#{i}", repositoryId: '1' } } }
      let(:deployment_hash) do
        {
          associations: [
            { associationType: 'issueKeys', values: issue_keys },
            { associationType: 'commit', values: commits }
          ],
          deploymentSequenceNumber: 1
        }
      end

      before do
        allow(Gitlab::ErrorTracking).to receive(:track_exception)
      end

      it 'fills the budget from issueKeys first, then from remaining types' do
        result = client.send(:truncate_associations_if_needed, deployment_hash)

        expect(result[:associations].sum { |a| a[:values].size }).to eq(500)
        expect(result[:associations][0]).to eq({ associationType: 'issueKeys', values: issue_keys })
        expect(result[:associations][1][:associationType]).to eq('commit')
        expect(result[:associations][1][:values].size).to eq(100)
      end

      it 'drops association entries that end up empty after truncation' do
        deployment = deployment_hash.deep_dup
        deployment[:associations].first[:values] = (1..500).map { |i| "JIRA-#{i}" }

        result = client.send(:truncate_associations_if_needed, deployment)

        expect(result[:associations].size).to eq(1)
        expect(result[:associations].first[:associationType]).to eq('issueKeys')
      end

      it 'prioritises issueKeys even when they are emitted last' do
        deployment = {
          associations: [
            { associationType: 'commit', values: (1..400).map { |i| "sha#{i}" } },
            { associationType: 'issueKeys', values: (1..400).map { |i| "JIRA-#{i}" } }
          ],
          deploymentSequenceNumber: 1
        }

        result = client.send(:truncate_associations_if_needed, deployment)

        expect(result[:associations][0][:associationType]).to eq('issueKeys')
        expect(result[:associations][0][:values].size).to eq(400)
        expect(result[:associations][1][:associationType]).to eq('commit')
        expect(result[:associations][1][:values].size).to eq(100)
      end

      it 'skips empty-value associations without consuming budget' do
        deployment = {
          associations: [
            { associationType: 'commit', values: [] },
            { associationType: 'issueKeys', values: (1..600).map { |i| "JIRA-#{i}" } }
          ],
          deploymentSequenceNumber: 1
        }

        result = client.send(:truncate_associations_if_needed, deployment)

        expect(result[:associations].size).to eq(1)
        expect(result[:associations].first[:associationType]).to eq('issueKeys')
        expect(result[:associations].first[:values].size).to eq(500)
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
      stub_full_request("https://gitlab-test.atlassian.net#{path}", method: :post)
        .with(body: body, headers: expected_headers(path, 'POST'))
        .to_return(body: response_body, headers: { 'Content-Type': 'application/json' })
    end

    it "calls the API with auth headers" do
      subject.send(:store_ff_info, project: project, feature_flags: feature_flags)
    end

    it 'only sends information about relevant MRs' do
      expect(subject).to receive(:post).with(
        '/rest/featureflags/0.1/bulk', { flags: have_attributes(size: 2), properties: Hash }
      ).and_call_original

      subject.send(:store_ff_info, project: project, feature_flags: feature_flags)
    end

    it 'does not call the API if there is nothing to report' do
      expect(subject).not_to receive(:post)

      subject.send(:store_ff_info, project: project, feature_flags: [feature_flags.last])
    end

    context 'when there are errors' do
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
      stub_full_request("https://gitlab-test.atlassian.net#{path}", method: :post)
        .with(body: body, headers: expected_headers(path, 'POST'))
        .to_return(body: response_body, headers: { 'Content-Type': 'application/json' })
    end

    it "calls the API with auth headers" do
      subject.send(:store_build_info, project: project, pipelines: pipelines)
    end

    it 'only sends information about relevant MRs' do
      expect(subject).to receive(:post)
        .with('/rest/builds/0.1/bulk', { builds: have_attributes(size: 8) })
        .and_call_original

      subject.send(:store_build_info, project: project, pipelines: pipelines)
    end

    it 'does not call the API if there is nothing to report' do
      expect(subject).not_to receive(:post)

      subject.send(:store_build_info, project: project, pipelines: pipelines.take(1))
    end

    context 'when there are errors' do
      let(:failures) do
        [{ errors: [{ message: 'X' }, { message: 'Y' }] }, { errors: [{ message: 'Z' }] }]
      end

      it 'reports the errors' do
        response = subject.send(:store_build_info, project: project, pipelines: pipelines)

        expect(response['errorMessages']).to eq(%w[X Y Z])
        expect(response['responseCode']).to eq(200)
        expect(response['requestBody']).to be_a(Hash)
      end
    end

    it 'avoids N+1 database queries' do
      pending 'https://gitlab.com/gitlab-org/gitlab/-/issues/292818'

      baseline = ActiveRecord::QueryRecorder.new do
        subject.send(:store_build_info, project: project, pipelines: pipelines)
      end

      pipelines << create(:ci_pipeline, project: project, head_pipeline_of: create(:merge_request, :jira_branch, source_project: project))

      expect do
        subject.send(:store_build_info, project: project, pipelines: pipelines)
      end.not_to exceed_query_limit(baseline)
    end
  end

  describe '#store_dev_info' do
    let_it_be(:merge_requests) { create_list(:merge_request, 2, :unique_branches, source_project: project) }

    before do
      path = '/rest/devinfo/0.10/bulk'

      stub_full_request("https://gitlab-test.atlassian.net#{path}", method: :post)
        .with(headers: expected_headers(path, 'POST'))
    end

    it "calls the API with auth headers" do
      subject.send(:store_dev_info, project: project)
    end

    it 'avoids N+1 database queries' do
      control = ActiveRecord::QueryRecorder.new do
        subject.send(:store_dev_info, project: project, merge_requests: merge_requests)
      end

      merge_requests << create(:merge_request, :unique_branches, source_project: project)

      expect do
        subject.send(:store_dev_info, project: project,
          merge_requests: merge_requests)
      end.not_to exceed_query_limit(control)
    end
  end

  describe '#remove_branch_info' do
    let_it_be(:merge_requests) { create_list(:merge_request, 2, :unique_branches, source_project: project) }
    let(:branch_name) { merge_requests.first.source_branch }
    let(:jira_branch_id) { Digest::SHA256.hexdigest(branch_name) }
    let(:additional_headers) do
      { 'Accept' => 'application/json',
        'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
        'User-Agent' => 'Ruby' }
    end

    context 'when the branch exists' do
      before do
        delete_path = "/rest/devinfo/0.10/repository/#{project.id}/branch/#{jira_branch_id}"
        stub_full_request("https://gitlab-test.atlassian.net#{delete_path}", method: :delete)
          .with(headers: expected_headers(delete_path, 'DELETE').merge(additional_headers))
          .to_return(status: 200, body: "", headers: {})
      end

      it 'sends delete branch info' do
        expect(subject).to receive(:delete)
          .with("/rest/devinfo/0.10/repository/#{project.id}/branch/#{jira_branch_id}")
          .and_call_original
        expect(Gitlab::IntegrationsLogger).to receive(:info)
          .with({ message: "deleting jira branch id: #{jira_branch_id}, gitlab branch name: #{branch_name}" })
          .and_call_original

        subject.send(:remove_branch_info, project: project, remove_branch_info: branch_name)
      end
    end
  end

  describe '#user_info' do
    context 'when user is a site administrator' do
      let(:account_id) { '12345' }
      let(:response_body) do
        {
          groups: {
            items: [
              { name: 'site-admins' }
            ]
          }
        }.to_json
      end

      before do
        stub_full_request("https://gitlab-test.atlassian.net/rest/api/3/user?accountId=#{account_id}&expand=groups")
          .to_return(status: response_status, body: response_body, headers: { 'Content-Type': 'application/json' })
      end

      context 'with a successful response' do
        let(:response_status) { 200 }

        it 'returns a JiraUser instance' do
          jira_user = client.user_info(account_id)

          expect(jira_user).to be_a(Atlassian::JiraConnect::JiraUser)
          expect(jira_user).to be_jira_admin
        end
      end

      context 'with a failed response' do
        let(:response_status) { 401 }

        it 'returns nil' do
          expect(client.user_info(account_id)).to be_nil
        end
      end
    end

    context 'when user is an organization administrator' do
      let(:account_id) { '12345' }
      let(:response_body) do
        {
          groups: {
            items: [
              { name: 'org-admins' }
            ]
          }
        }.to_json
      end

      before do
        stub_full_request("https://gitlab-test.atlassian.net/rest/api/3/user?accountId=#{account_id}&expand=groups")
          .to_return(status: response_status, body: response_body, headers: { 'Content-Type': 'application/json' })
      end

      context 'with a successful response' do
        let(:response_status) { 200 }

        it 'returns a JiraUser instance' do
          jira_user = client.user_info(account_id)

          expect(jira_user).to be_a(Atlassian::JiraConnect::JiraUser)
          expect(jira_user).to be_jira_admin
        end
      end

      context 'with a failed response' do
        let(:response_status) { 401 }

        it 'returns nil' do
          expect(client.user_info(account_id)).to be_nil
        end
      end
    end
  end

  describe '#parse_jira_error_messages' do
    subject { client.send(:parse_jira_error_messages, data) }

    context 'with array data' do
      let(:data) { [{ 'message' => 'Error 1' }, { 'message' => 'Error 2' }] }

      it 'extracts messages from array' do
        expect(subject).to match_array(['Error 1', 'Error 2'])
      end
    end

    context 'with hash data containing message' do
      let(:data) { { 'message' => 'Single error' } }

      it 'returns message in array' do
        expect(subject).to match_array(['Single error'])
      end
    end

    context 'with hash data containing error' do
      let(:data) { { 'error' => 'Error message' } }

      it 'returns error in array' do
        expect(subject).to match_array(['Error message'])
      end
    end

    context 'with hash data without message or error' do
      let(:data) { { 'foo' => 'bar' } }

      it 'returns unknown error' do
        expect(subject).to match_array(['Unknown error'])
      end
    end

    context 'with unexpected data type' do
      let(:data) { 'string' }

      it 'returns invalid error format' do
        expect(subject).to match_array(['Unknown error'])
      end
    end
  end
end
