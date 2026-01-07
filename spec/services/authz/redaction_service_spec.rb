# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authz::RedactionService, feature_category: :permissions do
  let_it_be(:user) { create(:user) }
  let_it_be(:public_project) { create(:project, :public) }
  let_it_be(:private_project) { create(:project, :private) }
  let_it_be(:private_project_with_access) { create(:project, :private) }

  before_all do
    private_project_with_access.add_reporter(user)
  end

  describe '.supported_types' do
    it 'returns the list of supported resource types' do
      expect(described_class.supported_types).to include(
        'issues', 'merge_requests', 'projects', 'milestones', 'snippets'
      )
    end
  end

  describe '#initialize' do
    context 'when user is nil' do
      it 'raises ArgumentError' do
        expect do
          described_class.new(user: nil, resources_by_type: {}, source: 'test')
        end.to raise_error(ArgumentError, 'user is required')
      end
    end

    context 'when user is provided' do
      it 'does not raise an error' do
        expect do
          described_class.new(user: user, resources_by_type: {}, source: 'test')
        end.not_to raise_error
      end
    end
  end

  describe '#execute' do
    subject(:result) { service.execute }

    let(:service) { described_class.new(user: user, resources_by_type: resources_by_type, source: 'test') }

    context 'with empty resources' do
      let(:resources_by_type) { {} }

      it 'returns an empty hash' do
        expect(result).to eq({})
      end
    end

    context 'with issues' do
      let_it_be(:public_issue) { create(:issue, project: public_project) }
      let_it_be(:private_issue) { create(:issue, project: private_project) }
      let_it_be(:accessible_issue) { create(:issue, project: private_project_with_access) }
      let_it_be(:confidential_issue) { create(:issue, :confidential, project: private_project_with_access) }

      context 'when user has access to public issue' do
        let(:resources_by_type) { { 'issues' => [public_issue.id] } }

        it 'allows access' do
          expect(result).to eq({ 'issues' => { public_issue.id => true } })
        end
      end

      context 'when user does not have access to private issue' do
        let(:resources_by_type) { { 'issues' => [private_issue.id] } }

        it 'denies access' do
          expect(result).to eq({ 'issues' => { private_issue.id => false } })
        end
      end

      context 'when user has project access' do
        let(:resources_by_type) { { 'issues' => [accessible_issue.id] } }

        it 'allows access' do
          expect(result).to eq({ 'issues' => { accessible_issue.id => true } })
        end
      end

      context 'when user has project access to confidential issue' do
        let(:resources_by_type) { { 'issues' => [confidential_issue.id] } }

        it 'allows access for project member' do
          expect(result).to eq({ 'issues' => { confidential_issue.id => true } })
        end
      end

      context 'when checking multiple issues at once' do
        let(:resources_by_type) do
          { 'issues' => [public_issue.id, private_issue.id, accessible_issue.id] }
        end

        it 'returns correct authorization for each issue' do
          expect(result).to eq({
            'issues' => {
              public_issue.id => true,
              private_issue.id => false,
              accessible_issue.id => true
            }
          })
        end
      end
    end

    context 'with merge_requests' do
      let_it_be(:public_mr) { create(:merge_request, source_project: public_project) }
      let_it_be(:private_mr) { create(:merge_request, source_project: private_project) }
      let_it_be(:accessible_mr) { create(:merge_request, source_project: private_project_with_access) }

      context 'when user has access to public MR' do
        let(:resources_by_type) { { 'merge_requests' => [public_mr.id] } }

        it 'allows access' do
          expect(result).to eq({ 'merge_requests' => { public_mr.id => true } })
        end
      end

      context 'when user does not have access to private MR' do
        let(:resources_by_type) { { 'merge_requests' => [private_mr.id] } }

        it 'denies access' do
          expect(result).to eq({ 'merge_requests' => { private_mr.id => false } })
        end
      end

      context 'when user has project access' do
        let(:resources_by_type) { { 'merge_requests' => [accessible_mr.id] } }

        it 'allows access' do
          expect(result).to eq({ 'merge_requests' => { accessible_mr.id => true } })
        end
      end
    end

    context 'with projects' do
      context 'when user can access public project' do
        let(:resources_by_type) { { 'projects' => [public_project.id] } }

        it 'allows access' do
          expect(result).to eq({ 'projects' => { public_project.id => true } })
        end
      end

      context 'when user cannot access private project' do
        let(:resources_by_type) { { 'projects' => [private_project.id] } }

        it 'denies access' do
          expect(result).to eq({ 'projects' => { private_project.id => false } })
        end
      end

      context 'when user has project access' do
        let(:resources_by_type) { { 'projects' => [private_project_with_access.id] } }

        it 'allows access' do
          expect(result).to eq({ 'projects' => { private_project_with_access.id => true } })
        end
      end
    end

    context 'with non-existent resources' do
      let(:resources_by_type) { { 'issues' => [non_existing_record_id] } }

      it 'denies access to non-existent resources' do
        expect(result).to eq({ 'issues' => { non_existing_record_id => false } })
      end
    end

    context 'with mixed resource types' do
      let_it_be(:public_issue) { create(:issue, project: public_project) }
      let_it_be(:private_mr) { create(:merge_request, source_project: private_project) }

      let(:resources_by_type) do
        {
          'issues' => [public_issue.id],
          'merge_requests' => [private_mr.id],
          'projects' => [public_project.id, private_project.id]
        }
      end

      it 'handles multiple resource types correctly' do
        expect(result).to eq({
          'issues' => { public_issue.id => true },
          'merge_requests' => { private_mr.id => false },
          'projects' => {
            public_project.id => true,
            private_project.id => false
          }
        })
      end
    end

    context 'with empty arrays for a type' do
      let(:resources_by_type) { { 'issues' => [] } }

      it 'returns empty hash for that type' do
        expect(result).to eq({ 'issues' => {} })
      end
    end

    context 'with unsupported resource type' do
      let(:resources_by_type) { { 'unknown_type' => [1, 2, 3] } }

      it 'denies access for all IDs of unsupported type' do
        expect(result).to eq({ 'unknown_type' => { 1 => false, 2 => false, 3 => false } })
      end
    end

    context 'with milestones' do
      let_it_be(:public_milestone) { create(:milestone, project: public_project) }
      let_it_be(:private_milestone) { create(:milestone, project: private_project) }

      context 'when user can access public milestone' do
        let(:resources_by_type) { { 'milestones' => [public_milestone.id] } }

        it 'allows access' do
          expect(result).to eq({ 'milestones' => { public_milestone.id => true } })
        end
      end

      context 'when user cannot access private milestone' do
        let(:resources_by_type) { { 'milestones' => [private_milestone.id] } }

        it 'denies access' do
          expect(result).to eq({ 'milestones' => { private_milestone.id => false } })
        end
      end
    end

    context 'with snippets' do
      let_it_be(:public_snippet) { create(:project_snippet, :public, project: public_project) }
      let_it_be(:private_snippet) { create(:project_snippet, :private, project: private_project) }
      let_it_be(:accessible_snippet) { create(:project_snippet, :private, project: private_project_with_access) }

      context 'when user can access public snippet' do
        let(:resources_by_type) { { 'snippets' => [public_snippet.id] } }

        it 'allows access' do
          expect(result).to eq({ 'snippets' => { public_snippet.id => true } })
        end
      end

      context 'when user cannot access private snippet' do
        let(:resources_by_type) { { 'snippets' => [private_snippet.id] } }

        it 'denies access' do
          expect(result).to eq({ 'snippets' => { private_snippet.id => false } })
        end
      end

      context 'when user has project access' do
        let(:resources_by_type) { { 'snippets' => [accessible_snippet.id] } }

        it 'allows access' do
          expect(result).to eq({ 'snippets' => { accessible_snippet.id => true } })
        end
      end
    end

    context 'with logger parameter' do
      let(:logger) { instance_double(Logger) }
      let(:service) do
        described_class.new(user: user, resources_by_type: resources_by_type, source: 'knowledge_graph', logger: logger)
      end

      let(:resources_by_type) { { 'issues' => [] } }

      it 'accepts a logger parameter' do
        expect { service }.not_to raise_error
        expect(result).to eq({ 'issues' => {} })
      end

      context 'when resources are redacted' do
        let_it_be(:private_issue) { create(:issue, project: private_project) }
        let(:resources_by_type) { { 'issues' => [private_issue.id] } }

        it 'logs redacted results' do
          expect(logger).to receive(:error).with(
            hash_including(
              class: 'Authz::RedactionService',
              message: 'redacted_authorization_results',
              source: 'knowledge_graph',
              user_id: user.id,
              total_requested: 1,
              total_redacted: 1,
              redacted_by_type: { 'issues' => 1 }
            )
          )

          result
        end
      end

      context 'when no resources are redacted' do
        let_it_be(:public_issue) { create(:issue, project: public_project) }
        let(:resources_by_type) { { 'issues' => [public_issue.id] } }

        it 'does not log' do
          expect(logger).not_to receive(:error)

          result
        end
      end
    end
  end

  describe 'visible_result? behavior' do
    let(:service) { described_class.new(user: user, resources_by_type: resources_by_type, source: 'test') }

    context 'when resource does not respond to to_ability_name' do
      let(:plain_object) { Struct.new(:id).new(999) }
      let(:resources_by_type) { { 'issues' => [999] } }

      before do
        allow(service).to receive(:load_all_resources).and_return({
          'issues' => { 999 => plain_object }
        })
      end

      it 'denies access for resources without to_ability_name (fail safe)' do
        result = service.execute
        expect(result).to eq({ 'issues' => { 999 => false } })
      end
    end

    context 'when resource has no policy' do
      let(:object_without_policy) do
        Struct.new(:id, :to_ability_name).new(888, 'unknown_object')
      end

      let(:resources_by_type) { { 'issues' => [888] } }

      before do
        allow(service).to receive(:load_all_resources).and_return({
          'issues' => { 888 => object_without_policy }
        })
        allow(DeclarativePolicy).to receive(:has_policy?).with(object_without_policy).and_return(false)
      end

      it 'denies access for resources without policy (fail safe)' do
        result = service.execute
        expect(result).to eq({ 'issues' => { 888 => false } })
      end
    end
  end

  describe 'load_resources_for_type behavior' do
    context 'when resource type has no preload associations defined' do
      let_it_be(:public_issue) { create(:issue, project: public_project) }
      let(:resources_by_type) { { 'issues' => [public_issue.id] } }
      let(:service) { described_class.new(user: user, resources_by_type: resources_by_type, source: 'test') }

      before do
        stub_const("#{described_class}::PRELOAD_ASSOCIATIONS", described_class::PRELOAD_ASSOCIATIONS.except('issues'))
      end

      it 'does not raise an error when preloads are not defined' do
        expect { service.execute }.not_to raise_error
      end

      it 'still performs authorization correctly' do
        result = service.execute
        expect(result).to eq({ 'issues' => { public_issue.id => true } })
      end
    end
  end

  describe 'performance optimization' do
    let_it_be(:issues) { create_list(:issue, 3, project: public_project) }
    let(:resources_by_type) { { 'issues' => issues.map(&:id) } }
    let(:service) { described_class.new(user: user, resources_by_type: resources_by_type, source: 'test') }

    it 'uses DeclarativePolicy.user_scope for optimization' do
      expect(DeclarativePolicy).to receive(:user_scope).and_call_original
      service.execute
    end

    it 'batch loads resources to prevent N+1 queries' do
      service.execute

      new_service = described_class.new(user: user, resources_by_type: resources_by_type, source: 'test')

      expect do
        new_service.execute
      end.not_to exceed_query_limit(10) # Reasonable limit for batch operation
    end

    it 'preloads nested associations to avoid N+1 in policies' do
      service.execute

      expect(described_class::PRELOAD_ASSOCIATIONS['issues']).to include(
        a_hash_including(project: array_including(:namespace, :project_feature))
      )
    end
  end
end
