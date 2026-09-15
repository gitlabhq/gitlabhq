# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::Groups::ListGroupsTool, feature_category: :mcp_server do
  let_it_be(:user) { create(:user) }
  let_it_be(:top_group) { create(:group, name: 'Alpha Searchable Group') }
  let_it_be(:other_top_group) { create(:group, name: 'Other Top Group') }
  let_it_be(:other_subgroup) { create(:group, parent: other_top_group, name: 'Other Subgroup') }
  let_it_be(:internal_top_group) { create(:group, :internal, name: 'Internal Top Group') }
  let_it_be(:subgroup) { create(:group, parent: top_group, name: 'Direct Subgroup') }
  let_it_be(:nested_subgroup) { create(:group, parent: subgroup, name: 'Nested Subgroup') }
  let_it_be(:private_group_mine) { create(:group, :private, name: 'Private Mine') }
  let_it_be(:private_group_not_member) { create(:group, :private, name: 'Private Not Member') }
  let_it_be(:archived_group_mine) do
    create(:group, name: 'Archived Mine', namespace_settings: create(:namespace_settings, archived: true))
  end

  let(:params) { {} }
  let(:tool) { described_class.new(current_user: user, params: params) }

  def result_full_paths(result)
    result[:structuredContent]['nodes'].map { |node| node['fullPath'] }
  end

  before_all do
    top_group.add_developer(user)
    internal_top_group.add_developer(user)
    private_group_mine.add_developer(user)
    archived_group_mine.add_developer(user)
  end

  describe 'versioning' do
    it 'registers version 0.1.0' do
      expect(tool.version).to eq(Mcp::Tools::Concerns::Constants::VERSIONS[:v0_1_0])
    end

    it 'reads the groups root field' do
      expect(tool.operation_name).to eq('groups')
    end
  end

  describe '#build_variables' do
    it 'defaults to the top-level groups of your memberships with the default page size', :aggregate_failures do
      variables = tool.build_variables

      expect(variables[:first]).to eq(20)
      expect(variables[:topLevelOnly]).to be(true)
      expect(variables[:allAvailable]).to be(false)
    end

    it 'omits filters that are not provided', :aggregate_failures do
      variables = tool.build_variables

      expect(variables).not_to have_key(:search)
      expect(variables).not_to have_key(:parentPath)
      expect(variables).not_to have_key(:includeSubgroups)
      expect(variables).not_to have_key(:visibilityLevel)
      expect(variables).not_to have_key(:after)
    end

    context 'with filters and pagination' do
      let(:params) do
        {
          search: 'alpha',
          visibility: 'internal',
          first: 25,
          after: 'cursor1'
        }
      end

      it 'maps them to GraphQL variables', :aggregate_failures do
        variables = tool.build_variables

        expect(variables[:search]).to eq('alpha')
        expect(variables[:visibilityLevel]).to eq('internal')
        expect(variables[:first]).to eq(25)
        expect(variables[:after]).to eq('cursor1')
      end
    end

    context 'when include_subgroups is given without group_id' do
      let(:params) { { include_subgroups: true } }

      it 'widens the listing beyond top-level groups', :aggregate_failures do
        variables = tool.build_variables

        expect(variables[:includeSubgroups]).to be(true)
        expect(variables[:topLevelOnly]).to be(false)
      end
    end

    describe 'parent scoping' do
      context 'when group_id is a numeric ID' do
        let(:params) { { group_id: top_group.id.to_s } }

        it 'resolves the parent full path and widens beyond memberships', :aggregate_failures do
          variables = tool.build_variables

          expect(variables[:parentPath]).to eq(top_group.full_path)
          expect(variables[:topLevelOnly]).to be(false)
          expect(variables[:allAvailable]).to be(true)
        end
      end

      context 'when group_id is a full path' do
        let(:params) { { group_id: top_group.full_path } }

        it 'resolves the parent full path into parentPath' do
          expect(tool.build_variables[:parentPath]).to eq(top_group.full_path)
        end
      end

      context 'when group_id and include_subgroups are both given' do
        let(:params) { { group_id: top_group.full_path, include_subgroups: true } }

        it 'requests descendant traversal', :aggregate_failures do
          variables = tool.build_variables

          expect(variables[:parentPath]).to eq(top_group.full_path)
          expect(variables[:includeSubgroups]).to be(true)
        end
      end

      context 'when group_id does not exist' do
        let(:params) { { group_id: non_existing_record_id.to_s } }

        it 'raises before executing GraphQL' do
          expect { tool.build_variables }.to raise_error(StandardError, /not found or inaccessible/)
        end
      end

      context 'when group_id is not accessible' do
        let(:params) { { group_id: private_group_not_member.full_path } }

        it 'denies access' do
          expect { tool.build_variables }.to raise_error(StandardError, /not found or inaccessible/)
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
        variables: hash_including(first: 20, topLevelOnly: true, allAvailable: false),
        context: hash_including(current_user: user)
      )
    end

    it 'returns the groups connection shaped for agent consumption', :aggregate_failures do
      result = tool.execute

      expect(result[:isError]).to be(false)
      expect(result[:content].first[:type]).to eq('text')
      expect(result[:structuredContent]).to have_key('pageInfo')
      expect(result[:structuredContent]).to have_key('nodes')
    end

    it 'lists the top-level groups of the user memberships by default' do
      expect(result_full_paths(tool.execute)).to contain_exactly(
        top_group.full_path, internal_top_group.full_path, private_group_mine.full_path
      )
    end

    it 'does not list public groups the user is not a member of' do
      expect(result_full_paths(tool.execute)).not_to include(other_top_group.full_path)
    end

    it 'excludes archived groups' do
      expect(result_full_paths(tool.execute)).not_to include(archived_group_mine.full_path)
    end

    it 'returns the fields agents need for follow-up calls', :aggregate_failures do
      node = tool.execute[:structuredContent]['nodes'].find { |group| group['fullPath'] == top_group.full_path }

      expect(node['id']).to eq(top_group.id)
      expect(node['name']).to eq(top_group.name)
      expect(node['visibility']).to eq('public')
      expect(node['webUrl']).to be_present
      expect(node['parent']).to be_nil
    end

    describe 'filtering' do
      context 'when group_id is given' do
        let(:params) { { group_id: top_group.full_path } }

        it 'lists only direct subgroups' do
          expect(result_full_paths(tool.execute)).to contain_exactly(subgroup.full_path)
        end

        it 'exposes the parent id on each subgroup' do
          node = tool.execute[:structuredContent]['nodes'].first

          expect(node.dig('parent', 'id')).to eq(top_group.id)
        end
      end

      context 'when group_id and include_subgroups are both given' do
        let(:params) { { group_id: top_group.full_path, include_subgroups: true } }

        it 'lists all descendants recursively' do
          expect(result_full_paths(tool.execute)).to contain_exactly(
            subgroup.full_path, nested_subgroup.full_path
          )
        end
      end

      context 'when include_subgroups is given without group_id' do
        let(:params) { { include_subgroups: true } }

        it 'lists the user groups at any depth, not the whole instance', :aggregate_failures do
          full_paths = result_full_paths(tool.execute)

          expect(full_paths).to include(top_group.full_path, subgroup.full_path, nested_subgroup.full_path)
          expect(full_paths).not_to include(other_top_group.full_path, other_subgroup.full_path)
          expect(full_paths).not_to include(private_group_not_member.full_path)
        end
      end

      context 'when group_id points to a group the user is not a member of' do
        let(:params) { { group_id: other_top_group.full_path } }

        it 'still lists its subgroups the user can see' do
          expect(result_full_paths(tool.execute)).to contain_exactly(other_subgroup.full_path)
        end
      end

      context 'when filtering by search' do
        let(:params) { { search: 'Alpha Searchable' } }

        it 'returns only matching groups' do
          expect(result_full_paths(tool.execute)).to contain_exactly(top_group.full_path)
        end
      end

      context 'when filtering by visibility' do
        let(:params) { { visibility: 'internal' } }

        it 'returns only groups with that visibility' do
          expect(result_full_paths(tool.execute)).to contain_exactly(internal_top_group.full_path)
        end
      end
    end

    describe 'authorization' do
      it 'never returns a private group the user is not a member of' do
        expect(result_full_paths(tool.execute)).not_to include(private_group_not_member.full_path)
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
