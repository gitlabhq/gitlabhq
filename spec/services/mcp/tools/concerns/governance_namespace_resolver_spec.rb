# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::Concerns::GovernanceNamespaceResolver, feature_category: :mcp_server do
  let_it_be(:group) { create(:group) }
  let_it_be(:subgroup) { create(:group, parent: group) }
  let_it_be(:project) { create(:project, group: subgroup) }

  let(:declared) { described_class::DEFAULT_NAMESPACE_ARGUMENTS }

  let(:tool_class) do
    args = declared

    Class.new do
      include Mcp::Tools::Concerns::GovernanceNamespaceResolver

      define_singleton_method(:namespace_arguments) { args }
    end
  end

  describe '#resolve_governance_containers' do
    context 'with a project argument' do
      it 'resolves a numeric id to the project' do
        arguments = { project_id: project.id.to_s }

        expect(tool_class.new.resolve_governance_containers(arguments.with_indifferent_access)).to eq([project])
      end

      it 'resolves a full path' do
        arguments = { project_id: project.full_path }

        expect(tool_class.new.resolve_governance_containers(arguments.with_indifferent_access)).to eq([project])
      end

      it 'resolves a Global ID' do
        arguments = { project_id: "gid://gitlab/Project/#{project.id}" }

        expect(tool_class.new.resolve_governance_containers(arguments.with_indifferent_access)).to eq([project])
      end
    end

    context 'with a Global ID of the wrong type' do
      it 'ignores a group Global ID in a project argument' do
        arguments = { project_id: "gid://gitlab/Group/#{project.id}" }

        expect(tool_class.new.resolve_governance_containers(arguments.with_indifferent_access)).to be_empty
      end

      it 'ignores a project Global ID in a group argument' do
        declared = { group: :group_id }
        klass = Class.new do
          include Mcp::Tools::Concerns::GovernanceNamespaceResolver
          define_singleton_method(:namespace_arguments) { declared }
        end
        arguments = { group_id: "gid://gitlab/Project/#{group.id}" }

        expect(klass.new.resolve_governance_containers(arguments.with_indifferent_access)).to be_empty
      end

      it 'ignores a Global ID naming a class that does not exist' do
        arguments = { project_id: 'gid://gitlab/NoSuchThing/1' }

        expect(tool_class.new.resolve_governance_containers(arguments.with_indifferent_access)).to be_empty
      end
    end

    context 'with a group argument' do
      it 'resolves a subgroup as given' do
        arguments = { group_id: subgroup.full_path }

        expect(tool_class.new.resolve_governance_containers(arguments.with_indifferent_access)).to eq([subgroup])
      end
    end

    context 'when the argument holds a list' do
      let(:declared) { { project: :project_ids } }

      it 'resolves every entry that exists' do
        other = create(:project, group: group)
        arguments = { project_ids: ["gid://gitlab/Project/#{project.id}", "gid://gitlab/Project/#{other.id}"] }

        expect(tool_class.new.resolve_governance_containers(arguments.with_indifferent_access))
          .to contain_exactly(project, other)
      end

      it 'skips entries that do not resolve' do
        arguments = {
          project_ids: ["gid://gitlab/Project/#{project.id}", "gid://gitlab/Project/#{non_existing_record_id}"]
        }

        expect(tool_class.new.resolve_governance_containers(arguments.with_indifferent_access)).to eq([project])
      end

      # The list is unbounded and this runs before the tool authorizes anything, so a
      # query per entry would let a caller decide what the check costs.
      it 'resolves the whole list in one query' do
        others = create_list(:project, 3, group: group)
        ids = ([project] + others).map { |target| "gid://gitlab/Project/#{target.id}" }
        arguments = { project_ids: ids }.with_indifferent_access

        expect { tool_class.new.resolve_governance_containers(arguments) }
          .to issue_same_number_of_queries_as {
            tool_class.new.resolve_governance_containers(
              { project_ids: ["gid://gitlab/Project/#{project.id}"] }.with_indifferent_access
            )
          }
      end
    end

    context 'when one argument names either a project or a group' do
      let(:declared) { { project_or_group: :full_path } }

      it 'resolves a project' do
        arguments = { full_path: project.full_path }

        expect(tool_class.new.resolve_governance_containers(arguments.with_indifferent_access)).to eq([project])
      end

      it 'falls through to a group when no project matches' do
        arguments = { full_path: subgroup.full_path }

        expect(tool_class.new.resolve_governance_containers(arguments.with_indifferent_access)).to eq([subgroup])
      end
    end

    context 'when nothing resolves' do
      it 'returns an empty array for absent arguments' do
        expect(tool_class.new.resolve_governance_containers({}.with_indifferent_access)).to be_empty
      end

      it 'returns an empty array for an unknown identifier' do
        arguments = { project_id: 'no/such/project' }

        expect(tool_class.new.resolve_governance_containers(arguments.with_indifferent_access)).to be_empty
      end

      context 'when the tool declares no namespace argument' do
        let(:declared) { {} }

        it 'returns an empty array' do
          arguments = { project_id: project.id.to_s }

          expect(tool_class.new.resolve_governance_containers(arguments.with_indifferent_access)).to be_empty
        end
      end

      context 'when the tool declares a kind the resolver does not read' do
        let(:declared) { { namespace: :namespace_id } }

        it 'returns an empty array' do
          arguments = { namespace_id: subgroup.full_path }

          expect(tool_class.new.resolve_governance_containers(arguments.with_indifferent_access)).to be_empty
        end
      end
    end
  end
end
