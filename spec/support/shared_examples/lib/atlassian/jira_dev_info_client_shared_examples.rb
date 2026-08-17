# frozen_string_literal: true

# The behaviour every Atlassian::Jira::DevInfoClient subclass inherits, run
# against each subclass so a change to the base cannot pass through one auth
# model while breaking the other.
#
# Usage:
#   it_behaves_like 'a Jira dev-info client', auth_error_message: 'Invalid JWT'
#
#   The including spec must define `client`.
RSpec.shared_examples 'a Jira dev-info client' do |auth_error_message:|
  describe 'dev-info client contract' do
    describe '#send_info' do
      let(:contract_project) { instance_double(Project) }

      it 'dispatches every info type to its store method' do
        expect(client).to receive(:store_dev_info)
          .with(project: contract_project, update_sequence_id: :seq, commits: :a, branches: :b, merge_requests: :c)
          .and_return(:dev)
        expect(client).to receive(:store_build_info)
          .with(project: contract_project, update_sequence_id: :seq, pipelines: :p).and_return(:build)
        expect(client).to receive(:store_deploy_info)
          .with(project: contract_project, update_sequence_id: :seq, deployments: :d).and_return(:deploy)
        expect(client).to receive(:remove_branch_info)
          .with(project: contract_project, update_sequence_id: :seq, remove_branch_info: :r).and_return(:removed)
        expect(client).to receive(:store_ff_info)
          .with(project: contract_project, update_sequence_id: :seq, feature_flags: :f).and_return(:ff)

        result = client.send_info(
          project: contract_project, update_sequence_id: :seq,
          commits: :a, branches: :b, merge_requests: :c,
          pipelines: :p, deployments: :d, remove_branch_info: :r, feature_flags: :f
        )

        expect(result).to contain_exactly(:dev, :build, :deploy, :removed, :ff)
      end

      it 'dispatches only the info types it was given' do
        expect(client).to receive(:store_dev_info)
          .with(project: contract_project, update_sequence_id: :seq, commits: :a).and_return(:dev)

        expect(client.send_info(project: contract_project, update_sequence_id: :seq, commits: :a))
          .to contain_exactly(:dev)
      end

      it 'raises when no info type matches' do
        expect { client.send_info(project: contract_project, builds: :typo) }.to raise_error(ArgumentError)
      end
    end

    describe '#handle_response' do
      using RSpec::Parameterized::TableSyntax

      # A name the base class cannot hold hardcoded, so the 403 branch proves
      # it interpolates what the caller passed.
      let(:operation) { 'builds' }
      let(:request) { instance_double(HTTParty::Request, raw_body: { repositories: [] }.to_json) }
      let(:response) do
        instance_double(HTTParty::Response, code: code, parsed_response: parsed_response, request: request)
      end

      let(:processed) { client.send(:handle_response, response, operation) { |data| [:yielded, data] } }

      context 'when Jira accepts the payload' do
        where(:code) { [200, 202] }

        with_them do
          let(:parsed_response) { :payload }

          it 'yields the parsed response' do
            expect(processed).to eq([:yielded, :payload])
          end
        end
      end

      context 'when Jira rejects the payload' do
        where(:case_name, :code, :parsed_response, :expected) do
          'the request is malformed' | 400 | [{ 'message' => 'X' }] | lazy do
            { 'errorMessages' => ['X'], 'response' => parsed_response, 'requestBody' => { 'repositories' => [] } }
          end
          'the credential is rejected' | 401 | nil | lazy { { 'errorMessages' => [auth_error_message] } }
          'the app lacks the module'   | 403 | nil | lazy do
            { 'errorMessages' => ["App does not support #{operation}"] }
          end
          'the payload is too large' | 413 | { 'errorMessages' => ['too big'] } | lazy do
            { 'errorMessages' => ['Data too large', 'too big'] }
          end
          'we are rate limited'        | 429 | nil | lazy { { 'errorMessages' => ['Rate limit exceeded'] } }
          'Jira is unavailable'        | 503 | nil | lazy { { 'errorMessages' => ['Service unavailable'] } }
          'the status is unmapped'     | 418 | :teapot | lazy do
            { 'errorMessages' => ['Unknown error'], 'response' => :teapot }
          end
        end

        with_them do
          it 'reports the failure and the status' do
            expect(processed).to eq(expected.merge('responseCode' => code))
          end
        end
      end
    end

    describe '#headers' do
      it 'authenticates the request' do
        expect(client.send(:headers, 'https://example.test', 'POST'))
          .to include('Authorization' => be_present, 'Content-Type' => 'application/json')
      end
    end
  end
end
