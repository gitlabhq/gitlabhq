# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::Concerns::ResourceFinder, feature_category: :mcp_server do
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

  shared_examples 'parent access control' do |parent_type, factory, error_prefix|
    let_it_be(:user) { create(:user) }
    let_it_be(:accessible_resource) { create(factory) } # rubocop:disable Rails/SaveBang -- This is a factory, not a Rails method call
    let_it_be(:inaccessible_resource) { create(factory, :private) }
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

  shared_examples 'resource finder' do |finder_method, resource_factory|
    let(:resource) { create(resource_factory) } # rubocop:disable Rails/SaveBang -- This is a factory, not a Rails method call

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
    it_behaves_like 'resource finder', :test_find_project, :project

    it 'validates input type' do
      expect { service.test_find_project(123) }
        .to raise_error(ArgumentError, "project_id must be a string")
      expect { service.test_find_project(nil) }
        .to raise_error(ArgumentError, "project_id must be a string")
    end

    it 'excludes hidden projects' do
      hidden_project = create(:project, :hidden)
      expect { service.test_find_project(hidden_project.id.to_s) }
        .to raise_error(StandardError, /not found or inaccessible/)
    end

    it 'handles special characters in path' do
      project = create(:project, path: 'test-project_123')
      expect(service.test_find_project(project.full_path)).to eq(project)
    end
  end

  describe '#find_group' do
    it_behaves_like 'resource finder', :test_find_group, :group

    it 'finds nested groups by full path' do
      parent = create(:group)
      nested = create(:group, parent: parent)
      expect(service.test_find_group(nested.full_path)).to eq(nested)
    end
  end

  describe '#find_parent_by_id_or_path' do
    context 'with project parent type' do
      it_behaves_like 'parent access control', :project, :project, 'Access denied to project'

      it 'finds and returns the project by ID' do
        user = create(:user)
        project = create(:project, :public)
        project.add_developer(user)
        service = test_class.new(user)

        result = service.test_find_parent_by_id_or_path(:project, project.id.to_s)
        expect(result).to eq(project)
      end
    end

    context 'with group parent type' do
      it_behaves_like 'parent access control', :group, :group, 'Access denied to group'

      it 'finds and returns the group by ID' do
        user = create(:user)
        group = create(:group)
        group.add_developer(user)
        service = test_class.new(user)

        result = service.test_find_parent_by_id_or_path(:group, group.id.to_s)
        expect(result).to eq(group)
      end
    end
  end

  describe '#find_work_item_in_parent' do
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project, :public) }
    let_it_be(:work_item) { create(:work_item, :issue, project: project, iid: 42) }
    let(:service) { test_class.new(user) }

    before_all do
      project.add_developer(user)
    end

    context 'with project parent' do
      it 'finds work item by iid' do
        result = service.test_find_work_item_in_parent(project, work_item.iid)
        expect(result).to eq(work_item)
      end

      it 'raises error when work item not found' do
        expect { service.test_find_work_item_in_parent(project, 99999) }
          .to raise_error(ArgumentError, 'Work item #99999 not found')
      end

      it 'restricts access to confidential work items for guests' do
        confidential_item = create(:work_item, :issue, :confidential, project: project, iid: 99)
        guest_user = create(:user)
        project.add_guest(guest_user)
        guest_service = test_class.new(guest_user)

        expect { guest_service.test_find_work_item_in_parent(project, confidential_item.iid) }
          .to raise_error(ArgumentError, "Work item ##{confidential_item.iid} not found")
      end
    end
  end

  describe '#build_work_item_finder_params' do
    it 'returns project_id for project parent' do
      project = create(:project)
      expect(service.test_build_work_item_finder_params(project))
        .to eq({ project_id: project.id })
    end

    it 'returns group_id and include_descendants for group parent' do
      group = create(:group)
      expect(service.test_build_work_item_finder_params(group))
        .to eq({ group_id: group.id, include_descendants: false })
    end

    it 'returns empty hash for unsupported parent type' do
      expect(service.test_build_work_item_finder_params(Object.new)).to eq({})
    end
  end

  describe '#authorize_parent_access!' do
    let_it_be(:user) { create(:user) }
    let(:service) { test_class.new(user) }

    shared_examples 'authorization check' do |parent_type, factory|
      let_it_be(:accessible) { create(factory) } # rubocop:disable Rails/SaveBang -- This is a factory, not a Rails method call
      let_it_be(:inaccessible) { create(factory, :private) }

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
      it_behaves_like 'authorization check', :project, :project
    end

    context 'with group parent' do
      it_behaves_like 'authorization check', :group, :group
    end
  end

  describe '#can_read_parent?' do
    let_it_be(:user) { create(:user) }
    let(:service) { test_class.new(user) }

    shared_examples 'permission check' do |parent_type, factory|
      let_it_be(:accessible) { create(factory) } # rubocop:disable Rails/SaveBang -- This is a factory, not a Rails method call
      let_it_be(:inaccessible) { create(factory, :private) }

      it 'returns true when user has permission' do
        accessible.add_developer(user)
        expect(service.test_can_read_parent?(accessible, parent_type)).to be true
      end

      it 'returns false when user lacks permission' do
        expect(service.test_can_read_parent?(inaccessible, parent_type)).to be false
      end
    end

    context 'with project parent' do
      it_behaves_like 'permission check', :project, :project
    end

    context 'with group parent' do
      it_behaves_like 'permission check', :group, :group
    end
  end
end
