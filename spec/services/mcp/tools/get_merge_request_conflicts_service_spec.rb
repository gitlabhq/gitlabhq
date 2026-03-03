# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::GetMergeRequestConflictsService, feature_category: :mcp_server do
  let(:service_name) { 'get_merge_request_conflicts' }

  describe 'version registration' do
    it 'registers version 0.1.0' do
      expect(described_class.version_exists?('0.1.0')).to be true
    end

    it 'has 0.1.0 as the latest version' do
      expect(described_class.latest_version).to eq('0.1.0')
    end

    it 'returns available versions in order' do
      expect(described_class.available_versions).to eq(['0.1.0'])
    end
  end

  describe 'version metadata' do
    describe 'version 0.1.0' do
      let(:metadata) { described_class.version_metadata('0.1.0') }

      it 'has correct description' do
        expect(metadata[:description]).to include('Get merge conflict content')
      end

      it 'has correct input schema' do
        expect(metadata[:input_schema]).to eq({
          type: 'object',
          properties: {
            project_id: {
              type: 'string',
              description: 'Project ID (numeric) or full path (e.g., "gitlab-org/gitlab")'
            },
            merge_request_iid: {
              type: 'integer',
              description: 'Merge request internal ID'
            }
          },
          required: %w[project_id merge_request_iid],
          additionalProperties: false
        })
      end
    end
  end

  describe 'initialization' do
    context 'when no version is specified' do
      it 'uses the latest version' do
        service = described_class.new(name: service_name)
        expect(service.version).to eq('0.1.0')
      end
    end

    context 'when version 0.1.0 is specified' do
      it 'uses version 0.1.0' do
        service = described_class.new(name: service_name, version: '0.1.0')
        expect(service.version).to eq('0.1.0')
      end
    end

    context 'when invalid version is specified' do
      it 'raises ArgumentError' do
        expect { described_class.new(name: service_name, version: '1.0.0') }
          .to raise_error(ArgumentError, 'Version 1.0.0 not found. Available: 0.1.0')
      end
    end
  end

  describe '#description' do
    it 'returns correct description' do
      service = described_class.new(name: service_name, version: '0.1.0')
      expect(service.description).to include('Get merge conflict content')
    end
  end

  describe '#input_schema' do
    it 'returns correct schema' do
      service = described_class.new(name: service_name, version: '0.1.0')
      expect(service.input_schema).to eq({
        type: 'object',
        properties: {
          project_id: {
            type: 'string',
            description: 'Project ID (numeric) or full path (e.g., "gitlab-org/gitlab")'
          },
          merge_request_iid: {
            type: 'integer',
            description: 'Merge request internal ID'
          }
        },
        required: %w[project_id merge_request_iid],
        additionalProperties: false
      })
    end
  end

  describe '#execute' do
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:oauth_token) { 'test_token_123' }

    let(:service) { described_class.new(name: service_name, version: '0.1.0') }

    before_all do
      project.add_developer(user)
    end

    before do
      service.set_cred(current_user: user, access_token: oauth_token)
    end

    context 'when using version 0.1.0' do
      context 'with numeric project_id' do
        context 'when merge request does not have conflicts' do
          let(:merge_request) { create(:merge_request, source_project: project, target_project: project) }
          let(:arguments) do
            {
              'project_id' => project.id.to_s,
              'merge_request_iid' => merge_request.iid
            }
          end

          it 'returns an error' do
            result = service.execute(params: { arguments: arguments })

            expect(result[:isError]).to be true
            expect(result[:content].first[:text]).to include('does not have conflicts')
          end
        end

        context 'when merge request has conflicts' do
          let(:merge_request) do
            create(:merge_request, source_branch: 'conflict-resolvable', target_branch: 'conflict-start',
              source_project: project, merge_status: :cannot_be_merged)
          end

          let(:arguments) do
            {
              'project_id' => project.id.to_s,
              'merge_request_iid' => merge_request.iid
            }
          end

          before do
            # Trigger mergeability check to populate diff_refs and detect conflicts
            ::MergeRequests::MergeabilityCheckService.new(merge_request).execute
          end

          it 'returns success with raw git conflict content' do
            result = service.execute(params: { arguments: arguments })

            expect(result[:isError]).to be false
            expect(result[:content]).to be_an(Array)
            expect(result[:content].first[:type]).to eq('text')

            text = result[:content].first[:text]
            expect(text).to include('# File:')
            expect(text).to include('<<<<<<')
            expect(text).to include('======')
            expect(text).to include('>>>>>>')

            # structuredContent should be empty for raw text output
            expect(result[:structuredContent]).to eq({})
          end
        end
      end

      context 'with project full path' do
        let(:merge_request) do
          create(:merge_request, source_branch: 'conflict-resolvable', target_branch: 'conflict-start',
            source_project: project, merge_status: :cannot_be_merged)
        end

        let(:arguments) do
          {
            'project_id' => project.full_path,
            'merge_request_iid' => merge_request.iid
          }
        end

        before do
          # Trigger mergeability check to populate diff_refs and detect conflicts
          ::MergeRequests::MergeabilityCheckService.new(merge_request).execute
        end

        it 'finds the project by full path' do
          result = service.execute(params: { arguments: arguments })

          expect(result[:isError]).to be false
          expect(result[:content].first[:text]).to include('# File:')
          expect(result[:structuredContent]).to eq({})
        end
      end

      context 'when merge request is not found' do
        let(:arguments) do
          {
            'project_id' => project.id.to_s,
            'merge_request_iid' => 999999
          }
        end

        it 'returns an error' do
          result = service.execute(params: { arguments: arguments })

          expect(result[:isError]).to be true
          expect(result[:content].first[:text]).to match(/target object not found|Merge request not found/i)
        end
      end

      context 'when project is not found' do
        let(:arguments) do
          {
            'project_id' => '999999',
            'merge_request_iid' => 1
          }
        end

        it 'returns project not found error' do
          result = service.execute(params: { arguments: arguments })

          expect(result[:isError]).to be true
          expect(result[:content].first[:text]).to match(/project.*not found or inaccessible/i)
        end
      end

      context 'when project path is invalid' do
        let(:arguments) do
          {
            'project_id' => 'nonexistent/project',
            'merge_request_iid' => 1
          }
        end

        it 'returns project not found error' do
          result = service.execute(params: { arguments: arguments })

          expect(result[:isError]).to be true
          expect(result[:content].first[:text]).to match(/project.*not found or inaccessible/i)
        end
      end

      context 'when handling merge status states' do
        let(:arguments) do
          {
            'project_id' => project.id.to_s,
            'merge_request_iid' => merge_request.iid
          }
        end

        context 'when merge status is unchecked' do
          let(:merge_request) do
            create(:merge_request, source_project: project, target_project: project, merge_status: :unchecked)
          end

          it 'returns error indicating status not determined' do
            result = service.execute(params: { arguments: arguments })

            expect(result[:isError]).to be true
            expect(result[:content].first[:text]).to include("merge status is 'unchecked'")
            expect(result[:content].first[:text]).to include('mergeability has been checked')
          end
        end

        context 'when merge status is checking' do
          let(:merge_request) do
            create(:merge_request, source_project: project, target_project: project, merge_status: :checking)
          end

          it 'returns error indicating status being checked' do
            result = service.execute(params: { arguments: arguments })

            expect(result[:isError]).to be true
            expect(result[:content].first[:text]).to include("merge status is 'checking'")
            expect(result[:content].first[:text]).to include('mergeability has been checked')
          end
        end

        context 'when merge status is preparing' do
          let(:merge_request) do
            create(:merge_request, source_project: project, target_project: project, merge_status: :preparing)
          end

          it 'returns error indicating status being prepared' do
            result = service.execute(params: { arguments: arguments })

            expect(result[:isError]).to be true
            expect(result[:content].first[:text]).to include("merge status is 'preparing'")
            expect(result[:content].first[:text]).to include('mergeability has been checked')
          end
        end

        context 'when merge status is cannot_be_merged_recheck' do
          let(:merge_request) do
            create(:merge_request, source_project: project, target_project: project,
              merge_status: :cannot_be_merged_recheck)
          end

          it 'returns error indicating status not determined' do
            result = service.execute(params: { arguments: arguments })

            expect(result[:isError]).to be true
            expect(result[:content].first[:text]).to include("merge status is 'cannot_be_merged_recheck'")
            expect(result[:content].first[:text]).to include('mergeability has been checked')
          end
        end

        context 'when merge status is can_be_merged' do
          let(:merge_request) do
            create(:merge_request, source_project: project, target_project: project, merge_status: :can_be_merged)
          end

          it 'returns error indicating no conflicts' do
            result = service.execute(params: { arguments: arguments })

            expect(result[:isError]).to be true
            expect(result[:content].first[:text]).to eq('Merge request does not have conflicts')
          end
        end
      end

      context 'when guard clause: missing branches or incomplete diff refs' do
        let(:merge_request) do
          create(:merge_request, source_project: project, target_project: project,
            source_branch: 'deleted-branch', merge_status: :cannot_be_merged)
        end

        let(:arguments) do
          {
            'project_id' => project.id.to_s,
            'merge_request_iid' => merge_request.iid
          }
        end

        it 'returns error when branch is missing' do
          # The branch 'deleted-branch' doesn't exist in the test repo, so branch_missing? will be true
          result = service.execute(params: { arguments: arguments })

          expect(result[:isError]).to be true
          expect(result[:content].first[:text]).to include('Cannot retrieve conflicts: missing branches or diff refs')
        end
      end

      context 'when using memoization' do
        let(:merge_request) do
          create(:merge_request, source_branch: 'conflict-resolvable', target_branch: 'conflict-start',
            source_project: project, merge_status: :cannot_be_merged)
        end

        let(:arguments) do
          {
            'project_id' => project.id.to_s,
            'merge_request_iid' => merge_request.iid
          }
        end

        before do
          # Trigger mergeability check
          ::MergeRequests::MergeabilityCheckService.new(merge_request).execute
        end

        it 'does not perform duplicate database queries for merge_request' do
          # Mock find_merge_request to verify it's only called once
          # despite being used in both auth_target and perform_0_1_0
          call_count = 0

          allow(service).to receive(:find_merge_request).and_wrap_original do |method, *args|
            call_count += 1
            method.call(*args)
          end

          service.execute(params: { arguments: arguments })

          # find_merge_request should only be called once due to memoization
          expect(call_count).to eq(1)
        end
      end

      describe 'raw git conflict content' do
        let(:arguments) do
          {
            'project_id' => project.id.to_s,
            'merge_request_iid' => merge_request.iid
          }
        end

        context 'when merge request has valid conflicts' do
          let(:merge_request) do
            create(:merge_request, source_branch: 'conflict-resolvable', target_branch: 'conflict-start',
              source_project: project, merge_status: :cannot_be_merged)
          end

          before do
            # Trigger mergeability check to populate diff_refs and detect conflicts
            ::MergeRequests::MergeabilityCheckService.new(merge_request).execute
          end

          it 'returns raw git conflict content as plain text' do
            result = service.execute(params: { arguments: arguments })

            expect(result[:isError]).to be false
            expect(result[:content]).to be_an(Array)
            expect(result[:content].first[:type]).to eq('text')

            text = result[:content].first[:text]
            expect(text).to include('# File:')
            expect(text).to include('<<<<<<')
            expect(text).to include('======')
            expect(text).to include('>>>>>>')

            # structuredContent should be empty for raw text output
            expect(result[:structuredContent]).to eq({})
          end

          it 'includes file path markers' do
            result = service.execute(params: { arguments: arguments })

            text = result[:content].first[:text]
            expect(text).to match(/# File: .+/)
          end
        end
      end
    end

    context 'when current_user is not set' do
      it 'returns an error' do
        service_without_user = described_class.new(name: service_name, version: '0.1.0')
        result = service_without_user.execute(params: {
          arguments: {
            'project_id' => project.id.to_s,
            'merge_request_iid' => 1
          }
        })

        expect(result[:isError]).to be true
        expect(result[:content].first[:text]).to include('current_user is not set')
      end
    end

    context 'when user lacks push permission' do
      let(:merge_request) { create(:merge_request, source_project: project, target_project: project) }
      let_it_be(:guest_user) { create(:user) }

      let(:guest_service) { described_class.new(name: service_name, version: '0.1.0') }
      let(:arguments) do
        {
          'project_id' => project.id.to_s,
          'merge_request_iid' => merge_request.iid
        }
      end

      before_all do
        project.add_guest(guest_user)
      end

      before do
        guest_service.set_cred(current_user: guest_user, access_token: oauth_token)
      end

      it 'returns permission denied error' do
        result = guest_service.execute(params: { arguments: arguments })

        expect(result[:isError]).to be true
        expect(result[:content].first[:text]).to include('does not have permission to push to branch')
      end
    end
  end
end
