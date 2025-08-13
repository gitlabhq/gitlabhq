# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::GetMergeRequestChangesService, feature_category: :mcp_server do
  let(:service) { described_class.new(name: 'get_merge_request_changes') }

  describe '#description' do
    it 'returns the correct description' do
      expect(service.description).to eq('Get information about the merge request including its files and changes.')
    end
  end

  describe '#input_schema' do
    it 'returns the correct schema' do
      schema = service.input_schema

      expect(schema[:type]).to eq('object')
      expect(schema[:required]).to eq(%w[id merge_request_iid])
      expect(schema[:properties][:id][:type]).to eq('string')
      expect(schema[:properties][:id][:minLength]).to eq(1)
      expect(schema[:properties][:merge_request_iid][:type]).to eq('integer')
      expect(schema[:properties][:page][:type]).to eq('integer')
      expect(schema[:properties][:page][:minimum]).to eq(1)
      expect(schema[:properties][:per_page][:type]).to eq('integer')
      expect(schema[:properties][:per_page][:minimum]).to eq(1)
    end
  end

  describe '#execute' do
    let(:oauth_token) { 'token_123' }

    context 'with valid arguments' do
      let(:api_response) do
        instance_double(Gitlab::HTTP::Response, body: response_body, success?: success, code: response_code)
      end

      before do
        allow(Gitlab::HTTP).to receive(:get).and_return(api_response)
      end

      context 'with successful response' do
        let(:success) { true }
        let(:response_code) { 200 }
        let(:response_body) do
          [
            {
              'old_path' => 'app/models/user.rb',
              'new_path' => 'app/models/user.rb',
              'a_mode' => '100644',
              'b_mode' => '100644',
              'new_file' => false,
              'renamed_file' => false,
              'deleted_file' => false,
              'diff' => "@@ -1,4 +1,4 @@\n class User\n-  attr_accessor :name\n+  attr_accessor :name, :email\n end"
            },
            {
              'old_path' => 'spec/models/user_spec.rb',
              'new_path' => 'spec/models/user_spec.rb',
              'a_mode' => '100644',
              'b_mode' => '100644',
              'new_file' => false,
              'renamed_file' => false,
              'deleted_file' => false,
              'diff' => "@@ -1,3 +1,5 @@\n describe User do\n+  it 'has email' do\n+  end\n   it 'has name' do"
            },
            {
              'old_path' => nil,
              'new_path' => 'README.md',
              'a_mode' => '0',
              'b_mode' => '100644',
              'new_file' => true,
              'renamed_file' => false,
              'deleted_file' => false,
              'diff' => "@@ -0,0 +1,3 @@\n+# Project\n+\n+This is a test project."
            }
          ].to_json
        end

        let(:arguments) do
          { id: 'test-project', merge_request_iid: 10 }
        end

        it 'returns success response' do
          result = service.execute(oauth_token, arguments)

          expect(result[:isError]).to be false
          expect(result[:content].first[:type]).to eq('text')
          expect(result[:content].first[:text]).to include('class User')
          expect(result[:content].first[:text]).to include('describe User')
          expect(result[:content].first[:text]).to include('Project')
          expect(result[:structuredContent][:items].length).to eq(3)
          expect(result[:structuredContent][:metadata][:count]).to eq(3)
          expect(result[:structuredContent][:metadata][:has_more]).to be false
          expect(result[:structuredContent][:items].first['old_path']).to eq('app/models/user.rb')
          expect(result[:structuredContent][:items].first['new_path']).to eq('app/models/user.rb')
          expect(result[:structuredContent][:items].first['new_file']).to be false
          expect(result[:structuredContent][:items].first['deleted_file']).to be false
          expect(result[:structuredContent][:items].third['old_path']).to be_nil
          expect(result[:structuredContent][:items].third['new_path']).to eq('README.md')
          expect(result[:structuredContent][:items].third['new_file']).to be true
        end

        it 'makes request with correct URL' do
          service.execute(oauth_token, arguments)

          expect(Gitlab::HTTP).to have_received(:get).with(
            "#{Gitlab.config.gitlab.url}/api/v4/projects/test-project/merge_requests/10/diffs",
            hash_including(headers: hash_including('Authorization' => 'Bearer token_123'), query: {}, verify: false)
          )
        end

        context 'with pagination parameters' do
          let(:arguments) do
            { id: 'test-project', merge_request_iid: 10, page: 2, per_page: 50 }
          end

          it 'includes pagination parameters in query' do
            service.execute(oauth_token, arguments)

            expect(Gitlab::HTTP).to have_received(:get).with(
              "#{Gitlab.config.gitlab.url}/api/v4/projects/test-project/merge_requests/10/diffs",
              hash_including(
                headers: hash_including('Authorization' => 'Bearer token_123'),
                query: { page: 2, per_page: 50 },
                verify: false
              )
            )
          end
        end

        context 'with only page parameter' do
          let(:arguments) do
            { id: 'test-project', merge_request_iid: 10, page: 3 }
          end

          it 'includes only page parameter in query' do
            service.execute(oauth_token, arguments)

            expect(Gitlab::HTTP).to have_received(:get).with(
              "#{Gitlab.config.gitlab.url}/api/v4/projects/test-project/merge_requests/10/diffs",
              hash_including(
                headers: hash_including('Authorization' => 'Bearer token_123'), query: { page: 3 }, verify: false
              )
            )
          end
        end

        context 'with only per_page parameter' do
          let(:arguments) do
            { id: 'test-project', merge_request_iid: 10, per_page: 25 }
          end

          it 'includes only per_page parameter in query' do
            service.execute(oauth_token, arguments)

            expect(Gitlab::HTTP).to have_received(:get).with(
              "#{Gitlab.config.gitlab.url}/api/v4/projects/test-project/merge_requests/10/diffs",
              hash_including(
                headers: hash_including('Authorization' => 'Bearer token_123'), query: { per_page: 25 }, verify: false
              )
            )
          end
        end
      end

      context 'with single file change' do
        let(:success) { true }
        let(:response_code) { 200 }
        let(:response_body) do
          [
            {
              'old_path' => 'app/models/user.rb',
              'new_path' => 'app/models/user.rb',
              'new_file' => false,
              'renamed_file' => false,
              'deleted_file' => false,
              'diff' => "@@ -1,4 +1,4 @@\n class User\n-  attr_accessor :name\n+  attr_accessor :name, :email\n end"
            }
          ].to_json
        end

        let(:arguments) do
          { id: 'test-project', merge_request_iid: 10 }
        end

        it 'returns singular file text' do
          result = service.execute(oauth_token, arguments)

          expect(result[:content].first[:text]).to include('class User')
        end
      end

      context 'with project ID that needs encoding' do
        let(:success) { true }
        let(:response_code) { 200 }
        let(:response_body) { [].to_json }
        let(:arguments) do
          { id: 'foo-bar/gitlab', merge_request_iid: 1 }
        end

        it 'URL encodes the project ID' do
          service.execute(oauth_token, arguments)

          expect(Gitlab::HTTP).to have_received(:get).with(
            "#{Gitlab.config.gitlab.url}/api/v4/projects/foo-bar%2Fgitlab/merge_requests/1/diffs",
            hash_including(headers: hash_including('Authorization' => 'Bearer token_123'), query: {}, verify: false)
          )
        end
      end

      context 'with empty diffs response' do
        let(:success) { true }
        let(:response_code) { 200 }
        let(:response_body) { [].to_json }
        let(:arguments) do
          { id: 'test-project', merge_request_iid: 10 }
        end

        it 'returns success response with empty array' do
          result = service.execute(oauth_token, arguments)

          expect(result[:isError]).to be false
          expect(result[:content]).to match_array([{ type: 'text', text: '' }])
          expect(result[:structuredContent]).to eq({ items: [], metadata: { count: 0, has_more: false } })
        end
      end
    end

    context 'with missing required field' do
      let(:arguments) do
        { id: 'test-project' }
      end

      it 'returns validation error' do
        result = service.execute(oauth_token, arguments)

        expect(result[:isError]).to be true
        expect(result[:content].first[:text]).to include('merge_request_iid is missing')
      end
    end
  end
end
