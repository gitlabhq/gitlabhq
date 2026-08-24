# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::Concerns::ResourceFinder, feature_category: :mcp_server do
  let_it_be(:user, freeze: true) { create(:user) }
  let_it_be(:public_group, freeze: true) { create(:group) }
  let_it_be(:private_group, freeze: true) { create(:group, :private) }
  let_it_be(:group) { public_group }
  let_it_be(:public_project, freeze: true) { create(:project, :public, group: group) }
  let_it_be(:private_project, freeze: true) { create(:project, :private, group: group) }

  let(:test_class) do
    Class.new do
      include Mcp::Tools::Concerns::ResourceFinder

      attr_accessor :current_user

      def initialize(user = nil)
        @current_user = user
      end

      def test_find_project(project_id, ability: :read_project)
        find_project!(project_id, ability: ability)
      end

      def test_find_project_without_bang(project_id)
        find_project(project_id)
      end

      def test_find_group(group_id, ability: :read_group)
        find_group!(group_id, ability: ability)
      end

      def test_find_parent_by_id_or_path(parent_type, identifier)
        find_parent_by_id_or_path!(parent_type, identifier)
      end

      def test_find_work_item_in_parent(parent, iid)
        find_work_item_in_parent!(parent, iid)
      end

      def test_build_work_item_finder_params(parent)
        build_work_item_finder_params(parent)
      end
    end
  end

  let(:service) { test_class.new(user) }

  describe '#find_project!' do
    subject(:find_project) { service.test_find_project(project_id_or_path) }

    let_it_be_with_refind(:project) { create(:project, :public) }

    let(:project_id_or_path) { project.id.to_s }

    context 'when user can access the project' do
      it 'finds by numeric ID' do
        expect(service.test_find_project(public_project.id.to_s)).to eq(public_project)
      end

      it 'finds by full path' do
        expect(service.test_find_project(public_project.full_path)).to eq(public_project)
      end
    end

    context 'when project does not exist' do
      it 'raises StandardError for non-existent ID' do
        expect { service.test_find_project(non_existing_record_id.to_s) }
          .to raise_error(StandardError, /not found or inaccessible/)
      end

      it 'raises StandardError for non-existent path' do
        expect { service.test_find_project('invalid/path') }
          .to raise_error(StandardError, /not found or inaccessible/)
      end
    end

    context 'when user cannot access the project' do
      let(:service) { test_class.new(user) }

      it 'raises the same error as for a missing project, preventing enumeration' do
        identifier = private_project.full_path
        expect { service.test_find_project(identifier) }
          .to raise_error(StandardError, "Project '#{identifier}' not found or inaccessible")
      end

      it 'raises the same error when looking up by ID' do
        identifier = private_project.id.to_s
        expect { service.test_find_project(identifier) }
          .to raise_error(StandardError, "Project '#{identifier}' not found or inaccessible")
      end
    end

    context 'when validating input type' do
      context 'with integer input' do
        let(:project_id_or_path) { 123 }

        it 'raises ArgumentError' do
          expect { find_project }
            .to raise_error(ArgumentError, 'project_id must be a string')
        end
      end

      context 'with nil input' do
        let(:project_id_or_path) { nil }

        it 'raises ArgumentError' do
          expect { find_project }
            .to raise_error(ArgumentError, 'project_id must be a string')
        end
      end
    end

    context 'when project is hidden' do
      before do
        project.update!(hidden: true)
      end

      it 'raises StandardError' do
        expect { find_project }.to raise_error(StandardError, /not found or inaccessible/)
      end
    end

    context 'with special characters in path' do
      before do
        project.update!(path: 'test-project_123')
      end

      let(:project_id_or_path) { project.full_path }

      it 'finds the project' do
        is_expected.to eq(project)
      end
    end

    context 'with a custom ability' do
      it 'raises when the user lacks the specified ability' do
        allow(Ability).to receive(:allowed?).and_call_original
        allow(Ability).to receive(:allowed?).with(user, :read_merge_request, public_project).and_return(false)

        expect { service.test_find_project(public_project.id.to_s, ability: :read_merge_request) }
          .to raise_error(StandardError, /not found or inaccessible/)
      end
    end
  end

  describe '#find_project' do
    subject(:find_project) { service.test_find_project_without_bang(project_id_or_path) }

    let(:project_id_or_path) { public_project.full_path }

    it 'returns the project' do
      is_expected.to eq(public_project)
    end

    context 'when the project does not exist' do
      let(:project_id_or_path) { 'does-not/exist' }

      it { is_expected.to be_nil }
    end
  end

  describe '#find_group!' do
    subject(:find_group) { service.test_find_group(group_full_path) }

    context 'when user can access the group' do
      let(:group_full_path) { public_group.full_path }

      it 'finds by full path' do
        is_expected.to eq(public_group)
      end

      it 'finds by numeric ID' do
        expect(service.test_find_group(public_group.id.to_s)).to eq(public_group)
      end
    end

    context 'when group does not exist' do
      it 'raises StandardError for non-existent ID' do
        expect { service.test_find_group(non_existing_record_id.to_s) }
          .to raise_error(StandardError, /not found or inaccessible/)
      end

      it 'raises StandardError for non-existent path' do
        expect { service.test_find_group('invalid/path') }
          .to raise_error(StandardError, /not found or inaccessible/)
      end
    end

    context 'when user cannot access the group' do
      it 'raises the same error as for a missing group, preventing enumeration' do
        identifier = private_group.full_path
        expect { service.test_find_group(identifier) }
          .to raise_error(StandardError, "Group '#{identifier}' not found or inaccessible")
      end

      it 'raises the same error when looking up by ID' do
        identifier = private_group.id.to_s
        expect { service.test_find_group(identifier) }
          .to raise_error(StandardError, "Group '#{identifier}' not found or inaccessible")
      end
    end

    context 'with nested groups' do
      let(:nested_group) { create(:group, parent: group) }
      let(:group_full_path) { nested_group.full_path }

      it 'finds by full path' do
        is_expected.to eq(nested_group)
      end
    end
  end

  describe '#find_parent_by_id_or_path!' do
    subject(:find_parent_by_id_or_path) do
      test_class.new(user).test_find_parent_by_id_or_path(parent_type, identifier)
    end

    context 'with project parent type' do
      context 'when user has access' do
        let(:user) { create(:user, developer_of: public_project) }
        let(:parent_type) { :project }
        let(:identifier) { public_project.full_path }

        it 'finds and returns the project' do
          is_expected.to eq(public_project)
        end
      end

      context 'when user lacks access' do
        let(:parent_type) { :project }
        let(:identifier) { private_project.full_path }

        it 'raises a uniform not-found error indistinguishable from a missing project' do
          expect { find_parent_by_id_or_path }
            .to raise_error(StandardError, "Project '#{identifier}' not found or inaccessible")
        end
      end

      context 'when finding by ID' do
        let(:user) { create(:user, developer_of: public_project) }
        let(:parent_type) { :project }
        let(:identifier) { public_project.id.to_s }

        it 'finds and returns the project' do
          is_expected.to eq(public_project)
        end
      end
    end

    context 'with group parent type' do
      context 'when user has access' do
        let(:user) { create(:user, developer_of: public_group) }
        let(:parent_type) { :group }
        let(:identifier) { public_group.full_path }

        it 'finds and returns the group' do
          is_expected.to eq(public_group)
        end
      end

      context 'when user lacks access' do
        let(:parent_type) { :group }
        let(:identifier) { private_group.full_path }

        it 'raises a uniform not-found error indistinguishable from a missing group' do
          expect { find_parent_by_id_or_path }
            .to raise_error(StandardError, "Group '#{identifier}' not found or inaccessible")
        end
      end

      context 'when finding by ID' do
        let(:user) { create(:user, developer_of: group) }
        let(:parent_type) { :group }
        let(:identifier) { group.id.to_s }

        it 'finds and returns the group' do
          is_expected.to eq(group)
        end
      end
    end
  end

  describe '#find_work_item_in_parent!' do
    let_it_be(:project) { public_project }
    let_it_be(:user) { create(:user, developer_of: [project]) }
    let_it_be(:work_item) { create(:work_item, :issue, project: project) }
    let(:work_item_iid) { work_item.iid }
    let(:service) { test_class.new(user) }

    subject(:find_work_item_in_parent) { service.test_find_work_item_in_parent(project, work_item_iid) }

    context 'with project parent' do
      it 'finds work item by iid' do
        is_expected.to eq(work_item)
      end

      context 'when work item not found' do
        let(:work_item_iid) { non_existing_record_iid }

        it 'raises error when work item not found' do
          expect { find_work_item_in_parent }
            .to raise_error(ArgumentError, "Work item ##{work_item_iid} not found or inaccessible")
        end
      end

      context 'when work item is confidential' do
        let(:confidential_item) { create(:work_item, :issue, :confidential, project: project) }
        let(:guest_user) { create(:user, guest_of: project) }
        let(:work_item_iid) { confidential_item.iid }
        let(:user) { guest_user }

        it 'restricts access' do
          expect { find_work_item_in_parent }
            .to raise_error(ArgumentError, "Work item ##{work_item_iid} not found or inaccessible")
        end
      end
    end
  end

  describe '#build_work_item_finder_params' do
    subject(:build_work_item_finder_params) { service.test_build_work_item_finder_params(parent) }

    context 'with project parent' do
      let(:parent) { public_project }

      it 'returns project_id' do
        is_expected.to eq(project_id: public_project.id)
      end
    end

    context 'with group parent' do
      let(:parent) { group }

      it 'returns group_id and include_descendants' do
        is_expected.to eq(group_id: group.id, include_descendants: false)
      end
    end

    context 'with unsupported parent type' do
      let(:parent) { Object.new }

      it 'returns empty hash' do
        is_expected.to eq({})
      end
    end
  end
end
