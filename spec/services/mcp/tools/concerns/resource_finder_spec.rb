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

      def test_find_project(project_id)
        find_project(project_id)
      end

      def test_find_group(group_id)
        find_group(group_id)
      end

      def test_find_parent_by_id_or_path(parent_type, identifier)
        find_parent_by_id_or_path(parent_type, identifier)
      end

      def test_find_work_item_in_parent(parent, iid)
        find_work_item_in_parent(parent, iid)
      end

      def test_build_work_item_finder_params(parent)
        build_work_item_finder_params(parent)
      end

      def test_authorize_parent_access!(parent, parent_type, identifier)
        authorize_parent_access!(parent, parent_type, identifier)
      end

      def test_can_read_parent?(parent, parent_type)
        can_read_parent?(parent, parent_type)
      end
    end
  end

  let(:service) { test_class.new }

  shared_examples 'parent access control' do |parent_type, public_resource, private_resource, error_prefix|
    let(:accessible_resource) { public_send(public_resource) }
    let(:inaccessible_resource) { public_send(private_resource) }
    let(:service) { test_class.new(user) }

    it 'allows access when user has permission' do
      accessible_resource.add_developer(user)
      expect { service.test_find_parent_by_id_or_path(parent_type, accessible_resource.full_path) }
        .not_to raise_error
    end

    it 'denies access when user lacks permission' do
      identifier = inaccessible_resource.full_path
      expect { service.test_find_parent_by_id_or_path(parent_type, identifier) }
        .to raise_error(ArgumentError, "#{error_prefix}: '#{identifier}'")
    end
  end

  shared_examples 'resource finder' do |finder_method, resource_ref|
    let(:resource) { public_send(resource_ref) }

    it 'finds resource by ID' do
      result = service.send(finder_method, resource.id.to_s)
      expect(result).to eq(resource)
    end

    it 'finds resource by full path' do
      result = service.send(finder_method, resource.full_path)
      expect(result).to eq(resource)
    end

    it 'raises error for non-existent ID' do
      expect { service.send(finder_method, non_existing_record_id.to_s) }
        .to raise_error(StandardError, /not found or inaccessible/)
    end

    it 'raises error for non-existent path' do
      expect { service.send(finder_method, 'invalid/path') }
        .to raise_error(StandardError, /not found or inaccessible/)
    end
  end

  describe '#find_project' do
    subject(:find_project) { service.test_find_project(project_id_or_path) }

    let_it_be_with_refind(:project) { create(:project) }

    let(:project_id_or_path) { project.id.to_s }

    it_behaves_like 'resource finder', :test_find_project, :public_project

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
  end

  describe '#find_group' do
    subject(:find_group) { service.test_find_group(group_full_path) }

    it_behaves_like 'resource finder', :test_find_group, :private_group

    context 'with nested groups' do
      let(:nested_group) { create(:group, parent: group) }
      let(:group_full_path) { nested_group.full_path }

      it 'finds by full path' do
        is_expected.to eq(nested_group)
      end
    end
  end

  describe '#find_parent_by_id_or_path' do
    subject(:find_parent_by_id_or_path) do
      test_class.new(user).test_find_parent_by_id_or_path(parent_type, identifier)
    end

    context 'with project parent type' do
      it_behaves_like 'parent access control', :project, :public_project, :private_project, 'Access denied to project'

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
      it_behaves_like 'parent access control', :group, :public_group, :private_group, 'Access denied to group'

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

  describe '#find_work_item_in_parent' do
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
            .to raise_error(ArgumentError, "Work item ##{work_item_iid} not found")
        end
      end

      context 'when work item is confidential' do
        let(:confidential_item) { create(:work_item, :issue, :confidential, project: project) }
        let(:guest_user) { create(:user, guest_of: project) }
        let(:work_item_iid) { confidential_item.iid }
        let(:user) { guest_user }

        it 'restricts access' do
          expect { find_work_item_in_parent }
            .to raise_error(ArgumentError, "Work item ##{work_item_iid} not found")
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

  describe '#authorize_parent_access!' do
    let(:service) { test_class.new(user) }

    shared_examples 'authorization check' do |parent_type, public_resource, private_resource|
      let(:accessible) { public_send(public_resource) }
      let(:inaccessible) { public_send(private_resource) }

      it 'passes when user has access' do
        accessible.add_developer(user)
        expect { service.test_authorize_parent_access!(accessible, parent_type, accessible.full_path) }
          .not_to raise_error
      end

      it 'raises error when user lacks access' do
        expect { service.test_authorize_parent_access!(inaccessible, parent_type, inaccessible.full_path) }
          .to raise_error(ArgumentError, "Access denied to #{parent_type}: '#{inaccessible.full_path}'")
      end
    end

    context 'with project parent' do
      it_behaves_like 'authorization check', :project, :public_project, :private_project
    end

    context 'with group parent' do
      it_behaves_like 'authorization check', :group, :public_group, :private_group
    end
  end

  describe '#can_read_parent?' do
    let(:service) { test_class.new(user) }

    shared_examples 'permission check' do |parent_type, public_resource, private_resource|
      let(:accessible) { public_send(public_resource) }
      let(:inaccessible) { public_send(private_resource) }

      it 'returns true when user has permission' do
        accessible.add_developer(user)
        expect(service.test_can_read_parent?(accessible, parent_type)).to be true
      end

      it 'returns false when user lacks permission' do
        expect(service.test_can_read_parent?(inaccessible, parent_type)).to be false
      end
    end

    context 'with project parent' do
      it_behaves_like 'permission check', :project, :public_project, :private_project
    end

    context 'with group parent' do
      it_behaves_like 'permission check', :group, :public_group, :private_group
    end
  end
end
