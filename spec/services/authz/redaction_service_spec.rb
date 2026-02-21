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
        'issue', 'merge_request', 'project', 'milestone', 'snippet', 'user', 'group', 'work_item'
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
        let(:resources_by_type) { { 'issue' => { 'ids' => [public_issue.id], 'ability' => 'read_issue' } } }

        it 'allows access' do
          expect(result).to eq({ 'issue' => { public_issue.id => true } })
        end
      end

      context 'when user does not have access to private issue' do
        let(:resources_by_type) { { 'issue' => { 'ids' => [private_issue.id], 'ability' => 'read_issue' } } }

        it 'denies access' do
          expect(result).to eq({ 'issue' => { private_issue.id => false } })
        end
      end

      context 'when user has project access' do
        let(:resources_by_type) { { 'issue' => { 'ids' => [accessible_issue.id], 'ability' => 'read_issue' } } }

        it 'allows access' do
          expect(result).to eq({ 'issue' => { accessible_issue.id => true } })
        end
      end

      context 'when user has project access to confidential issue' do
        let(:resources_by_type) { { 'issue' => { 'ids' => [confidential_issue.id], 'ability' => 'read_issue' } } }

        it 'allows access for project member' do
          expect(result).to eq({ 'issue' => { confidential_issue.id => true } })
        end
      end

      context 'when checking multiple issues at once' do
        let(:resources_by_type) do
          { 'issue' => { 'ids' => [public_issue.id, private_issue.id, accessible_issue.id],
                         'ability' => 'read_issue' } }
        end

        it 'returns correct authorization for each issue' do
          expect(result).to eq({
            'issue' => {
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
        let(:resources_by_type) do
          { 'merge_request' => { 'ids' => [public_mr.id], 'ability' => 'read_merge_request' } }
        end

        it 'allows access' do
          expect(result).to eq({ 'merge_request' => { public_mr.id => true } })
        end
      end

      context 'when user does not have access to private MR' do
        let(:resources_by_type) do
          { 'merge_request' => { 'ids' => [private_mr.id], 'ability' => 'read_merge_request' } }
        end

        it 'denies access' do
          expect(result).to eq({ 'merge_request' => { private_mr.id => false } })
        end
      end

      context 'when user has project access' do
        let(:resources_by_type) do
          { 'merge_request' => { 'ids' => [accessible_mr.id], 'ability' => 'read_merge_request' } }
        end

        it 'allows access' do
          expect(result).to eq({ 'merge_request' => { accessible_mr.id => true } })
        end
      end
    end

    context 'with projects' do
      context 'when user can access public project' do
        let(:resources_by_type) { { 'project' => { 'ids' => [public_project.id], 'ability' => 'read_project' } } }

        it 'allows access' do
          expect(result).to eq({ 'project' => { public_project.id => true } })
        end
      end

      context 'when user cannot access private project' do
        let(:resources_by_type) { { 'project' => { 'ids' => [private_project.id], 'ability' => 'read_project' } } }

        it 'denies access' do
          expect(result).to eq({ 'project' => { private_project.id => false } })
        end
      end

      context 'when user has project access' do
        let(:resources_by_type) do
          { 'project' => { 'ids' => [private_project_with_access.id], 'ability' => 'read_project' } }
        end

        it 'allows access' do
          expect(result).to eq({ 'project' => { private_project_with_access.id => true } })
        end
      end
    end

    context 'with non-existent resources' do
      let(:resources_by_type) { { 'issue' => { 'ids' => [non_existing_record_id], 'ability' => 'read_issue' } } }

      it 'denies access to non-existent resources' do
        expect(result).to eq({ 'issue' => { non_existing_record_id => false } })
      end
    end

    context 'with mixed resource types' do
      let_it_be(:public_issue) { create(:issue, project: public_project) }
      let_it_be(:private_mr) { create(:merge_request, source_project: private_project) }

      let(:resources_by_type) do
        {
          'issue' => { 'ids' => [public_issue.id], 'ability' => 'read_issue' },
          'merge_request' => { 'ids' => [private_mr.id], 'ability' => 'read_merge_request' },
          'project' => { 'ids' => [public_project.id, private_project.id], 'ability' => 'read_project' }
        }
      end

      it 'handles multiple resource types correctly' do
        expect(result).to eq({
          'issue' => { public_issue.id => true },
          'merge_request' => { private_mr.id => false },
          'project' => {
            public_project.id => true,
            private_project.id => false
          }
        })
      end
    end

    context 'with empty arrays for a type' do
      let(:resources_by_type) { { 'issue' => { 'ids' => [], 'ability' => 'read_issue' } } }

      it 'returns empty hash for that type' do
        expect(result).to eq({ 'issue' => {} })
      end
    end

    context 'with unsupported resource type' do
      let(:resources_by_type) { { 'unknown_type' => { 'ids' => [1, 2, 3], 'ability' => 'read_unknown' } } }

      it 'denies access for all IDs of unsupported type' do
        expect(result).to eq({ 'unknown_type' => { 1 => false, 2 => false, 3 => false } })
      end
    end

    context 'with milestones' do
      let_it_be(:public_milestone) { create(:milestone, project: public_project) }
      let_it_be(:private_milestone) { create(:milestone, project: private_project) }

      context 'when user can access public milestone' do
        let(:resources_by_type) do
          { 'milestone' => { 'ids' => [public_milestone.id], 'ability' => 'read_milestone' } }
        end

        it 'allows access' do
          expect(result).to eq({ 'milestone' => { public_milestone.id => true } })
        end
      end

      context 'when user cannot access private milestone' do
        let(:resources_by_type) do
          { 'milestone' => { 'ids' => [private_milestone.id], 'ability' => 'read_milestone' } }
        end

        it 'denies access' do
          expect(result).to eq({ 'milestone' => { private_milestone.id => false } })
        end
      end
    end

    context 'with snippets' do
      let_it_be(:public_snippet) { create(:project_snippet, :public, project: public_project) }
      let_it_be(:private_snippet) { create(:project_snippet, :private, project: private_project) }
      let_it_be(:accessible_snippet) { create(:project_snippet, :private, project: private_project_with_access) }

      context 'when user can access public snippet' do
        let(:resources_by_type) do
          { 'snippet' => { 'ids' => [public_snippet.id], 'ability' => 'read_snippet' } }
        end

        it 'allows access' do
          expect(result).to eq({ 'snippet' => { public_snippet.id => true } })
        end
      end

      context 'when user cannot access private snippet' do
        let(:resources_by_type) do
          { 'snippet' => { 'ids' => [private_snippet.id], 'ability' => 'read_snippet' } }
        end

        it 'denies access' do
          expect(result).to eq({ 'snippet' => { private_snippet.id => false } })
        end
      end

      context 'when user has project access' do
        let(:resources_by_type) do
          { 'snippet' => { 'ids' => [accessible_snippet.id], 'ability' => 'read_snippet' } }
        end

        it 'allows access' do
          expect(result).to eq({ 'snippet' => { accessible_snippet.id => true } })
        end
      end
    end

    context 'with users' do
      let_it_be(:public_user) { create(:user) }
      let_it_be(:private_user) { create(:user, private_profile: true) }

      context 'when user can access public user profile' do
        let(:resources_by_type) do
          { 'user' => { 'ids' => [public_user.id], 'ability' => 'read_user' } }
        end

        it 'allows access' do
          expect(result).to eq({ 'user' => { public_user.id => true } })
        end
      end

      context 'when user accesses private-profile user with read_user' do
        let(:resources_by_type) do
          { 'user' => { 'ids' => [private_user.id], 'ability' => 'read_user' } }
        end

        it 'allows access because read_user does not check private_profile' do
          expect(result).to eq({ 'user' => { private_user.id => true } })
        end
      end

      context 'when user accesses private-profile user with read_user_profile' do
        let(:resources_by_type) do
          { 'user' => { 'ids' => [private_user.id], 'ability' => 'read_user_profile' } }
        end

        it 'denies access because read_user_profile checks private_profile' do
          expect(result).to eq({ 'user' => { private_user.id => false } })
        end
      end

      context 'when user is viewing their own profile' do
        let(:resources_by_type) { { 'user' => { 'ids' => [user.id], 'ability' => 'read_user' } } }

        it 'allows access' do
          expect(result).to eq({ 'user' => { user.id => true } })
        end
      end

      context 'when checking multiple users at once' do
        let(:resources_by_type) do
          { 'user' => { 'ids' => [public_user.id, private_user.id, user.id], 'ability' => 'read_user' } }
        end

        it 'allows access for all users with read_user' do
          expect(result).to eq({
            'user' => {
              public_user.id => true,
              private_user.id => true,
              user.id => true
            }
          })
        end
      end
    end

    context 'with groups' do
      let_it_be(:public_group) { create(:group, :public) }
      let_it_be(:internal_group) { create(:group, :internal) }
      let_it_be(:private_group) { create(:group, :private) }
      let_it_be(:private_group_with_access) { create(:group, :private) }

      before_all do
        private_group_with_access.add_guest(user)
      end

      context 'when user can access public group' do
        let(:resources_by_type) { { 'group' => { 'ids' => [public_group.id], 'ability' => 'read_group' } } }

        it 'allows access' do
          expect(result).to eq({ 'group' => { public_group.id => true } })
        end
      end

      context 'when user can access internal group' do
        let(:resources_by_type) { { 'group' => { 'ids' => [internal_group.id], 'ability' => 'read_group' } } }

        it 'allows access for logged in user' do
          expect(result).to eq({ 'group' => { internal_group.id => true } })
        end
      end

      context 'when user cannot access private group without membership' do
        let(:resources_by_type) { { 'group' => { 'ids' => [private_group.id], 'ability' => 'read_group' } } }

        it 'denies access' do
          expect(result).to eq({ 'group' => { private_group.id => false } })
        end
      end

      context 'when user has group membership' do
        let(:resources_by_type) do
          { 'group' => { 'ids' => [private_group_with_access.id], 'ability' => 'read_group' } }
        end

        it 'allows access' do
          expect(result).to eq({ 'group' => { private_group_with_access.id => true } })
        end
      end

      context 'when checking multiple groups at once' do
        let(:resources_by_type) do
          { 'group' => { 'ids' => [public_group.id, private_group.id, private_group_with_access.id],
                         'ability' => 'read_group' } }
        end

        it 'returns correct authorization for each group' do
          expect(result).to eq({
            'group' => {
              public_group.id => true,
              private_group.id => false,
              private_group_with_access.id => true
            }
          })
        end
      end
    end

    context 'with work_items' do
      let_it_be(:public_work_item) { create(:work_item, project: public_project) }
      let_it_be(:private_work_item) { create(:work_item, project: private_project) }
      let_it_be(:accessible_work_item) { create(:work_item, project: private_project_with_access) }

      context 'when user has access to public work item' do
        let(:resources_by_type) do
          { 'work_item' => { 'ids' => [public_work_item.id], 'ability' => 'read_work_item' } }
        end

        it 'allows access' do
          expect(result).to eq({ 'work_item' => { public_work_item.id => true } })
        end
      end

      context 'when user does not have access to private work item' do
        let(:resources_by_type) do
          { 'work_item' => { 'ids' => [private_work_item.id], 'ability' => 'read_work_item' } }
        end

        it 'denies access' do
          expect(result).to eq({ 'work_item' => { private_work_item.id => false } })
        end
      end

      context 'when user has project access' do
        let(:resources_by_type) do
          { 'work_item' => { 'ids' => [accessible_work_item.id], 'ability' => 'read_work_item' } }
        end

        it 'allows access' do
          expect(result).to eq({ 'work_item' => { accessible_work_item.id => true } })
        end
      end

      context 'when checking multiple work items at once' do
        let(:resources_by_type) do
          { 'work_item' => { 'ids' => [public_work_item.id, private_work_item.id, accessible_work_item.id],
                             'ability' => 'read_work_item' } }
        end

        it 'returns correct authorization for each work item' do
          expect(result).to eq({
            'work_item' => {
              public_work_item.id => true,
              private_work_item.id => false,
              accessible_work_item.id => true
            }
          })
        end
      end
    end

    context 'with logger parameter' do
      let(:logger) { instance_double(Logger) }
      let(:service) do
        described_class.new(user: user, resources_by_type: resources_by_type, source: 'knowledge_graph', logger: logger)
      end

      let(:resources_by_type) { { 'issue' => { 'ids' => [], 'ability' => 'read_issue' } } }

      it 'accepts a logger parameter' do
        expect { service }.not_to raise_error
        expect(result).to eq({ 'issue' => {} })
      end

      context 'when resources are redacted' do
        let_it_be(:private_issue) { create(:issue, project: private_project) }
        let(:resources_by_type) { { 'issue' => { 'ids' => [private_issue.id], 'ability' => 'read_issue' } } }

        it 'logs redacted results' do
          expect(logger).to receive(:error).with(
            hash_including(
              class: 'Authz::RedactionService',
              message: 'redacted_authorization_results',
              source: 'knowledge_graph',
              user_id: user.id,
              total_requested: 1,
              total_redacted: 1,
              redacted_by_type: { 'issue' => 1 }
            )
          )

          result
        end
      end

      context 'when no resources are redacted' do
        let_it_be(:public_issue) { create(:issue, project: public_project) }
        let(:resources_by_type) { { 'issue' => { 'ids' => [public_issue.id], 'ability' => 'read_issue' } } }

        it 'does not log' do
          expect(logger).not_to receive(:error)

          result
        end
      end
    end
  end

  describe 'check_ability behavior' do
    let(:service) { described_class.new(user: user, resources_by_type: resources_by_type, source: 'test') }

    context 'when resource has no policy' do
      let(:object_without_policy) do
        Struct.new(:id).new(888)
      end

      let(:resources_by_type) { { 'issue' => { 'ids' => [888], 'ability' => 'read_issue' } } }

      before do
        allow(service).to receive(:load_all_resources).and_return({
          issue: { 888 => object_without_policy }
        })
        allow(DeclarativePolicy).to receive(:has_policy?).with(object_without_policy).and_return(false)
      end

      it 'denies access for resources without policy (fail safe)' do
        result = service.execute
        expect(result).to eq({ 'issue' => { 888 => false } })
      end
    end
  end

  describe 'ability-based authorization' do
    let_it_be(:public_issue) { create(:issue, project: public_project) }

    context 'when using different abilities' do
      let(:service) { described_class.new(user: user, resources_by_type: resources_by_type, source: 'test') }

      context 'with read ability' do
        let(:resources_by_type) { { 'issue' => { 'ids' => [public_issue.id], 'ability' => 'read_issue' } } }

        it 'allows access when user has read permission' do
          result = service.execute
          expect(result).to eq({ 'issue' => { public_issue.id => true } })
        end
      end

      context 'with update ability' do
        let(:resources_by_type) { { 'issue' => { 'ids' => [public_issue.id], 'ability' => 'update_issue' } } }

        it 'denies access when user lacks update permission' do
          result = service.execute
          expect(result).to eq({ 'issue' => { public_issue.id => false } })
        end
      end

      context 'with no ability (fail-closed)' do
        let(:resources_by_type) { { 'issue' => { 'ids' => [public_issue.id] } } }

        it 'denies access when no ability is specified' do
          result = service.execute
          expect(result).to eq({ 'issue' => { public_issue.id => false } })
        end
      end

      context 'with nil ability (fail-closed)' do
        let(:resources_by_type) { { 'issue' => { 'ids' => [public_issue.id], 'ability' => nil } } }

        it 'denies access when ability is nil' do
          result = service.execute
          expect(result).to eq({ 'issue' => { public_issue.id => false } })
        end
      end

      context 'with empty string ability (fail-closed)' do
        let(:resources_by_type) { { 'issue' => { 'ids' => [public_issue.id], 'ability' => '' } } }

        it 'denies access when ability is empty string' do
          result = service.execute
          expect(result).to eq({ 'issue' => { public_issue.id => false } })
        end
      end
    end
  end

  describe 'load_resources_for_type behavior' do
    context 'when resource type has no preload associations defined' do
      let_it_be(:public_issue) { create(:issue, project: public_project) }
      let(:resources_by_type) { { 'issue' => { 'ids' => [public_issue.id], 'ability' => 'read_issue' } } }
      let(:service) { described_class.new(user: user, resources_by_type: resources_by_type, source: 'test') }

      before do
        stub_const("#{described_class}::PRELOAD_ASSOCIATIONS", described_class::PRELOAD_ASSOCIATIONS.except(:issue))
      end

      it 'does not raise an error when preloads are not defined' do
        expect { service.execute }.not_to raise_error
      end

      it 'still performs authorization correctly' do
        result = service.execute
        expect(result).to eq({ 'issue' => { public_issue.id => true } })
      end
    end
  end

  describe 'performance optimization' do
    let_it_be(:issues) { create_list(:issue, 3, project: public_project) }
    let(:resources_by_type) { { 'issue' => { 'ids' => issues.map(&:id), 'ability' => 'read_issue' } } }
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
      end.not_to exceed_query_limit(10)
    end

    it 'preloads nested associations to avoid N+1 in policies' do
      service.execute

      expect(described_class::PRELOAD_ASSOCIATIONS[:issue]).to include(
        a_hash_including(project: array_including(:namespace, :project_feature))
      )
    end
  end
end
