# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::Concerns::GovernanceContainerResolver, feature_category: :mcp_server do
  let_it_be(:group) { create(:group) }
  let_it_be(:subgroup) { create(:group, parent: group) }
  let_it_be(:project) { create(:project, group: subgroup) }

  let(:declared) { described_class::DEFAULT_CONTAINER_ARGUMENTS }
  let(:base_url) { ::Gitlab.config.gitlab.url }

  let(:tool_class) do
    args = declared

    Class.new do
      include Mcp::Tools::Concerns::GovernanceContainerResolver

      define_singleton_method(:container_arguments) { args }
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

      it 'resolves a URL-encoded full path' do
        arguments = { project_id: ERB::Util.url_encode(project.full_path) }

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
          include Mcp::Tools::Concerns::GovernanceContainerResolver
          define_singleton_method(:container_arguments) { declared }
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

    context 'when the argument holds a url' do
      it 'resolves a project url' do
        arguments = { url: "#{base_url}/#{project.full_path}/-/merge_requests/1" }

        expect(tool_class.new.resolve_governance_containers(arguments.with_indifferent_access)).to eq([project])
      end

      it 'resolves a group url' do
        arguments = { url: "#{base_url}/groups/#{subgroup.full_path}/-/epics/1" }

        expect(tool_class.new.resolve_governance_containers(arguments.with_indifferent_access)).to eq([subgroup])
      end

      it 'resolves a url naming the container and nothing after it' do
        arguments = { url: "#{base_url}/#{project.full_path}" }

        expect(tool_class.new.resolve_governance_containers(arguments.with_indifferent_access)).to eq([project])
      end

      it 'returns an empty array when no container matches the path' do
        arguments = { url: "#{base_url}/no/such/project/-/merge_requests/1" }

        expect(tool_class.new.resolve_governance_containers(arguments.with_indifferent_access)).to be_empty
      end

      it 'returns an empty array for a malformed url' do
        arguments = { url: 'https://%%%' }

        expect(tool_class.new.resolve_governance_containers(arguments.with_indifferent_access)).to be_empty
      end
    end

    context 'when the tool reaches a merge request by url' do
      let(:tool_class) do
        args = declared

        Class.new do
          include Mcp::Tools::Concerns::GovernanceContainerResolver

          define_singleton_method(:container_arguments) { args }
        end
      end

      it 'resolves a url the generic path parser rejects' do
        arguments = { url: "#{base_url}/#{project.full_path}/-/merge_requests/7 " }

        expect(tool_class.new.resolve_governance_containers(arguments.with_indifferent_access)).to eq([project])
      end

      it 'resolves both the merge request url and an earlier path' do
        other_project = create(:project, group: group)
        url = "#{base_url}/#{other_project.full_path}/-/issues/1/" \
          "#{base_url}/#{project.full_path}/-/merge_requests/7"

        expect(tool_class.new.resolve_governance_containers({ url: url }.with_indifferent_access))
          .to contain_exactly(project, other_project)
      end

      it 'governs a url by every project a merge request or commit pattern reads from it', :aggregate_failures do
        commit_project = create(:project, group: group)
        url = "#{base_url}/#{project.full_path}/-/merge_requests/1 " \
          "#{base_url}/#{commit_project.full_path}/-/commit/#{'a' * 40}"
        resolved = tool_class.new.governed_containers({ url: url }.with_indifferent_access)

        expect(resolved.containers).to contain_exactly(project, commit_project)
        expect(resolved.named).to eq(2)
      end

      it 'falls back to the generic path parser for a url naming no merge request' do
        arguments = { url: "#{base_url}/groups/#{subgroup.full_path}/-/epics/1" }

        expect(tool_class.new.resolve_governance_containers(arguments.with_indifferent_access)).to eq([subgroup])
      end
    end

    context 'when the instance is served under a relative url root' do
      before do
        stub_config_setting(relative_url_root: '/gitlab')
      end

      it 'reads the same path the tools read' do
        arguments = { url: "https://example.com/gitlab/#{project.full_path}/-/merge_requests/7" }

        expect(tool_class.new.resolve_governance_containers(arguments.with_indifferent_access)).to eq([project])
      end
    end

    context 'when a url resolves to no container' do
      it 'still counts the url as a named identifier' do
        arguments = { url: 'https://%%%' }.with_indifferent_access

        expect(tool_class.new.governed_containers(arguments).named).to eq(1)
        expect(tool_class.new.governed_containers(arguments).containers).to be_empty
      end
    end

    context 'when an argument names more containers than the cap' do
      let(:declared) { { project: :project_ids } }
      let(:cap) { described_class::MAX_IDENTIFIERS_PER_ARGUMENT }

      it 'refuses the call' do
        arguments = { project_ids: Array.new(cap + 1) { |i| (i + 1).to_s } }.with_indifferent_access

        expect { tool_class.new.resolve_governance_containers(arguments) }
          .to raise_error(ArgumentError, /project_ids cannot name more than #{cap}/)
      end

      it 'resolves a list at the cap' do
        arguments = { project_ids: Array.new(cap) { |i| (i + 1).to_s } }.with_indifferent_access

        expect { tool_class.new.resolve_governance_containers(arguments) }.not_to raise_error
      end
    end
  end

  describe '#governed_containers' do
    context 'when a list argument names the same container twice' do
      let(:declared) { { project: :project_ids } }

      it 'counts a repeated Global ID once', :aggregate_failures do
        gid = "gid://gitlab/Project/#{project.id}"
        resolved = tool_class.new.governed_containers({ project_ids: [gid, gid] }.with_indifferent_access)

        expect(resolved.containers).to eq([project])
        expect(resolved.named).to eq(1)
      end

      it 'counts a repeated full path once', :aggregate_failures do
        arguments = { project_ids: [project.full_path, project.full_path] }.with_indifferent_access
        resolved = tool_class.new.governed_containers(arguments)

        expect(resolved.containers).to eq([project])
        expect(resolved.named).to eq(1)
      end
    end
  end

  describe 'argument guards' do
    context 'when the declared argument has no key' do
      let(:declared) { { project: nil } }

      it 'resolves nothing rather than reading every argument', :aggregate_failures do
        resolved = tool_class.new.governed_containers({ project_id: project.id.to_s }.with_indifferent_access)

        expect(resolved.containers).to be_empty
        expect(resolved.named).to eq(0)
      end
    end

    context 'when a list argument carries a blank entry' do
      let(:declared) { { project: :project_ids } }

      it 'skips the blank and keeps the rest', :aggregate_failures do
        arguments = { project_ids: ['', nil, project.id.to_s] }.with_indifferent_access
        resolved = tool_class.new.governed_containers(arguments)

        expect(resolved.containers).to eq([project])
        expect(resolved.named).to eq(1)
      end
    end

    context 'when a record resolves through its namespace' do
      let(:declared) { { record: { namespace_id: ->(id) { ::Namespace.find_by_id(id) } } } }

      it 'reaches the project behind a project namespace', :aggregate_failures do
        arguments = { namespace_id: project.project_namespace.id.to_s }.with_indifferent_access
        resolved = tool_class.new.governed_containers(arguments)

        expect(resolved.containers).to eq([project])
        expect(resolved.named).to eq(1)
      end

      it 'reaches a group' do
        arguments = { namespace_id: subgroup.id.to_s }.with_indifferent_access

        expect(tool_class.new.governed_containers(arguments).containers).to eq([subgroup])
      end

      it 'does not count a personal namespace, since no rules apply to it', :aggregate_failures do
        arguments = { namespace_id: create(:user, :with_namespace).namespace.id.to_s }.with_indifferent_access
        resolved = tool_class.new.governed_containers(arguments)

        expect(resolved.containers).to be_empty
        expect(resolved.named).to eq(0)
      end

      it 'counts a namespace that does not exist, so the call is refused', :aggregate_failures do
        arguments = { namespace_id: non_existing_record_id.to_s }.with_indifferent_access
        resolved = tool_class.new.governed_containers(arguments)

        expect(resolved.containers).to be_empty
        expect(resolved.named).to eq(1)
      end
    end
  end

  describe Mcp::Tools::Concerns::GovernanceContainerResolver::GovernanceContainerResolutionResult do
    it 'reads .none as naming nothing, so no rule applies' do
      expect(described_class.none).to be_none
    end

    it 'is not none? for a name that resolved to no container' do
      expect(described_class.new([], named: 1)).not_to be_none
    end

    it 'drops nils rather than counting them as resolved' do
      expect(described_class.new([nil], named: 1).containers).to be_empty
    end
  end
end
