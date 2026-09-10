# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::Projects::ListProjectsTool, feature_category: :mcp_server do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:subgroup) { create(:group, parent: group) }
  let_it_be(:project_mine_in_group) { create(:project, :public, group: group, name: 'Mine In Group') }
  let_it_be(:project_other_in_group) { create(:project, :public, group: group, name: 'Other In Group') }
  let_it_be(:project_in_subgroup) { create(:project, :public, group: subgroup, name: 'In Subgroup') }
  let_it_be(:project_mine_outside) { create(:project, :public, name: 'Mine Outside') }
  let_it_be(:internal_project_mine) { create(:project, :internal, name: 'Internal Mine') }
  let_it_be(:archived_project) { create(:project, :public, :archived, group: group, name: 'Archived In Group') }
  let_it_be(:private_project_not_member) do
    create(:project, :private, group: group, name: 'Private Not Member')
  end

  let(:params) { {} }
  let(:tool) { described_class.new(current_user: user, params: params) }

  def result_full_paths(result)
    result[:structuredContent]['nodes'].map { |node| node['fullPath'] }
  end

  before_all do
    project_mine_in_group.add_developer(user)
    project_mine_outside.add_developer(user)
    internal_project_mine.add_developer(user)
    archived_project.add_developer(user)
  end

  describe 'versioning' do
    it 'registers version 0.1.0' do
      expect(tool.version).to eq(Mcp::Tools::Concerns::Constants::VERSIONS[:v0_1_0])
    end

    it 'reads the projects root field by default' do
      expect(tool.operation_name).to eq('projects')
    end

    context 'when group_id alone is given' do
      let(:params) { { group_id: group.full_path } }

      it 'reads the group root field' do
        expect(tool.operation_name).to eq('group')
      end
    end

    context 'when group_id and min_access_level are both given' do
      let(:params) { { group_id: group.full_path, min_access_level: 'guest' } }

      it 'falls back to the projects root field' do
        expect(tool.operation_name).to eq('projects')
      end
    end
  end

  describe '#build_variables' do
    it 'applies the default page size, archived state, and access-level floor', :aggregate_failures do
      variables = tool.build_variables

      expect(variables[:first]).to eq(20)
      expect(variables[:archived]).to eq('EXCLUDE')
      expect(variables[:minAccessLevel]).to eq('GUEST')
      expect(variables[:useGroupBranch]).to be(false)
      expect(variables[:groupFullPath]).to eq('')
    end

    it 'omits filters that are not provided', :aggregate_failures do
      variables = tool.build_variables

      expect(variables).not_to have_key(:search)
      expect(variables).not_to have_key(:namespaceFullPath)
      expect(variables).not_to have_key(:visibilityLevel)
      expect(variables).not_to have_key(:after)
    end

    context 'with filters and pagination' do
      let(:params) do
        {
          search: 'dark mode',
          visibility: 'internal',
          archived: 'include',
          min_access_level: 'developer',
          first: 25,
          after: 'cursor1'
        }
      end

      it 'maps them to GraphQL variables without altering enum casing', :aggregate_failures do
        variables = tool.build_variables

        expect(variables[:search]).to eq('dark mode')
        expect(variables[:visibilityLevel]).to eq('internal')
        expect(variables[:archived]).to eq('INCLUDE')
        expect(variables[:minAccessLevel]).to eq('DEVELOPER')
        expect(variables[:first]).to eq(25)
        expect(variables[:after]).to eq('cursor1')
      end
    end

    describe 'group scoping' do
      context 'when group_id is a numeric ID' do
        let(:params) { { group_id: group.id.to_s } }

        it 'resolves the group full path into groupFullPath' do
          expect(tool.build_variables[:groupFullPath]).to eq(group.full_path)
        end
      end

      context 'when group_id is a full path' do
        let(:params) { { group_id: group.full_path } }

        it 'resolves the group full path into groupFullPath' do
          expect(tool.build_variables[:groupFullPath]).to eq(group.full_path)
        end
      end

      context 'when group_id does not exist' do
        let(:params) { { group_id: non_existing_record_id.to_s } }

        it 'raises before executing GraphQL' do
          expect { tool.build_variables }.to raise_error(StandardError, /not found or inaccessible/)
        end
      end

      context 'when group_id is not accessible' do
        let_it_be(:private_group) { create(:group, :private) }

        let(:params) { { group_id: private_group.full_path } }

        it 'denies access' do
          expect { tool.build_variables }.to raise_error(StandardError, /not found or inaccessible/)
        end
      end

      context 'when group_id and min_access_level are both given' do
        let(:params) { { group_id: group.full_path, min_access_level: 'developer' } }

        it 'resolves into namespaceFullPath instead, for the non-recursive fallback', :aggregate_failures do
          variables = tool.build_variables

          expect(variables[:namespaceFullPath]).to eq(group.full_path)
          expect(variables[:groupFullPath]).to eq('')
        end
      end
    end

    describe 'branch selection' do
      context 'with a bare call' do
        it 'uses the root projects field with the default access floor', :aggregate_failures do
          variables = tool.build_variables

          expect(variables[:useGroupBranch]).to be(false)
          expect(variables[:minAccessLevel]).to eq('GUEST')
        end
      end

      context 'when group_id alone is given' do
        let(:params) { { group_id: group.full_path } }

        it 'uses the subgroup-recursive group field, unrestricted by access level', :aggregate_failures do
          variables = tool.build_variables

          expect(variables[:useGroupBranch]).to be(true)
          expect(variables).not_to have_key(:minAccessLevel)
        end
      end

      context 'when group_id and min_access_level are both given' do
        let(:params) { { group_id: group.full_path, min_access_level: 'owner' } }

        it 'falls back to the non-recursive root field' do
          expect(tool.build_variables[:useGroupBranch]).to be(false)
        end
      end

      context 'when group_id and visibility are both given' do
        let(:params) { { group_id: group.full_path, visibility: 'public' } }

        it 'falls back to the non-recursive root field' do
          expect(tool.build_variables[:useGroupBranch]).to be(false)
        end
      end

      context 'when search and group_id are both given' do
        let(:params) { { search: 'x', group_id: group.full_path } }

        it 'still uses the group field, since search does not affect branch selection' do
          expect(tool.build_variables[:useGroupBranch]).to be(true)
        end
      end
    end
  end

  describe 'integration' do
    it 'executes the query as the current user with the resolved variables' do
      allow(GitlabSchema).to receive(:execute).and_call_original

      tool.execute

      expect(GitlabSchema).to have_received(:execute).with(
        anything,
        variables: hash_including(first: 20, minAccessLevel: 'GUEST', useGroupBranch: false),
        context: hash_including(current_user: user)
      )
    end

    it 'returns the projects connection shaped for agent consumption', :aggregate_failures do
      result = tool.execute

      expect(result[:isError]).to be(false)
      expect(result[:content].first[:type]).to eq('text')
      expect(result[:structuredContent]).to have_key('pageInfo')
      expect(result[:structuredContent]).to have_key('nodes')
      expect(result_full_paths(result)).to contain_exactly(
        project_mine_in_group.full_path, project_mine_outside.full_path, internal_project_mine.full_path
      )
    end

    it 'unwraps project ids to numeric integers that chain back into project_id', :aggregate_failures do
      node = tool.execute[:structuredContent]['nodes']
        .find { |project| project['fullPath'] == project_mine_outside.full_path }

      expect(node['id']).to eq(project_mine_outside.id)
      expect(node['id']).to be_an(Integer)
    end

    it 'unwraps project ids on the subgroup-recursive group branch too' do
      result = described_class.new(current_user: user, params: { group_id: group.full_path }).execute

      expect(result[:structuredContent]['nodes'].map { |p| p['id'] }).to all(be_an(Integer))
    end

    it 'does not return an unbounded total count' do
      expect(tool.execute[:structuredContent]).not_to have_key('count')
    end

    describe 'filtering' do
      context 'when group_id alone is given' do
        let(:params) { { group_id: group.full_path } }

        it 'returns every non-archived project in the group and its subgroups, regardless of access level' do
          expect(result_full_paths(tool.execute)).to contain_exactly(
            project_mine_in_group.full_path, project_other_in_group.full_path, project_in_subgroup.full_path
          )
        end

        it 'flags subgroupsIncluded as true' do
          expect(tool.execute[:structuredContent]['subgroupsIncluded']).to be(true)
        end
      end

      context 'when group_id and min_access_level are both given' do
        let(:params) { { group_id: group.full_path, min_access_level: 'developer' } }

        it 'restricts to that access level but no longer reaches subgroups' do
          expect(result_full_paths(tool.execute)).to contain_exactly(project_mine_in_group.full_path)
        end

        it 'flags subgroupsIncluded as false' do
          expect(tool.execute[:structuredContent]['subgroupsIncluded']).to be(false)
        end
      end

      context 'when group_id and visibility are both given' do
        let(:params) { { group_id: group.full_path, visibility: 'public' } }

        it 'flags subgroupsIncluded as false' do
          expect(tool.execute[:structuredContent]['subgroupsIncluded']).to be(false)
        end
      end

      context 'when group_id is not given' do
        let(:params) { {} }

        it 'omits subgroupsIncluded entirely' do
          expect(tool.execute[:structuredContent]).not_to have_key('subgroupsIncluded')
        end
      end

      context 'when filtering by search' do
        let(:params) { { search: project_mine_outside.name } }

        it 'stays scoped to the user projects' do
          expect(result_full_paths(tool.execute)).to contain_exactly(project_mine_outside.full_path)
        end
      end

      context 'when filtering by visibility' do
        let(:params) { { visibility: 'internal' } }

        it 'returns only projects with that visibility', :aggregate_failures do
          full_paths = result_full_paths(tool.execute)

          expect(full_paths).to include(internal_project_mine.full_path)
          expect(full_paths).not_to include(project_mine_in_group.full_path, project_mine_outside.full_path)
        end
      end

      context 'when archived is not provided, via the root fallback branch' do
        let(:params) { { group_id: group.full_path, min_access_level: 'developer' } }

        it 'excludes archived projects by default' do
          expect(result_full_paths(tool.execute)).not_to include(archived_project.full_path)
        end
      end

      context 'when filtering by archived: only, via the root fallback branch' do
        let(:params) { { group_id: group.full_path, min_access_level: 'developer', archived: 'only' } }

        it 'returns only archived projects' do
          expect(result_full_paths(tool.execute)).to contain_exactly(archived_project.full_path)
        end
      end

      context 'when filtering by archived: include, via the root fallback branch' do
        let(:params) { { group_id: group.full_path, min_access_level: 'developer', archived: 'include' } }

        it 'returns archived and non-archived projects' do
          expect(result_full_paths(tool.execute)).to contain_exactly(
            project_mine_in_group.full_path, archived_project.full_path
          )
        end
      end

      context 'when archived is not provided, via the group branch' do
        let(:params) { { group_id: group.full_path } }

        it 'excludes archived projects by default' do
          expect(result_full_paths(tool.execute)).not_to include(archived_project.full_path)
        end
      end

      context 'when filtering by archived: only, via the group branch' do
        let(:params) { { group_id: group.full_path, archived: 'only' } }

        it 'returns only archived projects' do
          expect(result_full_paths(tool.execute)).to contain_exactly(archived_project.full_path)
        end
      end
    end

    describe 'authorization' do
      let(:params) { { group_id: group.full_path } }

      it 'never returns a private project the user cannot access, even unrestricted by access level' do
        expect(result_full_paths(tool.execute)).not_to include(private_project_not_member.full_path)
      end
    end

    context 'when GraphQL returns errors' do
      before do
        allow(GitlabSchema).to receive(:execute).and_return({ 'errors' => [{ 'message' => 'Boom' }] })
      end

      it 'surfaces the error message', :aggregate_failures do
        result = tool.execute

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to include('Boom')
      end
    end
  end
end
