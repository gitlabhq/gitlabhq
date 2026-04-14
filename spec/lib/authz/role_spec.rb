# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Authz::Role, feature_category: :permissions do
  before do
    # clear any cached role data from prior specs before stubbing the path
    described_class.reset!
    stub_const("#{described_class}::BASE_PATH", 'spec/fixtures/authz/roles')
  end

  after do
    # clear the role cache so stubbed role data doesn't leak across tests since Authz::Role.get
    # caches instances in a class-level variable that persists.
    described_class.reset!
  end

  describe '.get' do
    it 'returns the cached instance for the same role name and only loads the role data once' do
      expect(described_class).to receive(:load_role_data).with(:guest).once

      first = described_class.get(:guest)
      second = described_class.get(:guest)

      expect(first).to be(second)
    end

    it 'raises an error for an unknown role' do
      expect { described_class.get(:nonexistent) }
        .to raise_error(ArgumentError, /Role definition not found/)
    end
  end

  describe '.reset!' do
    it 'clears cached instances' do
      first = described_class.get(:guest)
      described_class.reset!
      second = described_class.get(:guest)

      expect(first).not_to be(second)
    end
  end

  describe '.get_from_access_level' do
    it 'returns nil for NO_ACCESS' do
      expect(described_class.get_from_access_level(0)).to be_nil
    end

    it 'returns the role for a valid access level' do
      role = described_class.get_from_access_level(20)

      expect(role.permissions(:project)).to contain_exactly(
        :read_issue, :create_issue, :read_code, :download_code
      )
    end
  end

  describe '#permissions' do
    context 'when scoped to :project' do
      it 'returns only direct project permissions for a role with no inherited roles' do
        role = described_class.get(:guest)

        expect(role.permissions(:project)).to contain_exactly(:read_issue, :create_issue)
      end

      it 'returns all project permissions for a role including inherited permissions' do
        role = described_class.get(:reporter)

        expect(role.permissions(:project)).to contain_exactly(
          :read_issue, :create_issue, :read_code, :download_code
        )
      end

      it 'returns all project permissions recursively for roles with multi-level inheritance' do
        role = described_class.get(:developer)

        expect(role.permissions(:project)).to contain_exactly(
          :read_issue, :create_issue, # from guest
          :read_code, :download_code, # from reporter
          :push_code, :create_pipeline # from developer
        )
      end

      it 'expands assignable permissions so project permissions include raw and expanded assignable ones' do
        assignable = instance_double(Authz::PermissionGroups::Assignable, permissions: [:read_epic, :read_epic_board])
        allow(Authz::PermissionGroups::Assignable).to receive(:get).with(:read_work_item).and_return(assignable)

        role_data = {
          name: 'test_role', inherits_from: [],
          project: { raw_permissions: [:create_issue], permissions: [:read_work_item] },
          group: { raw_permissions: [], permissions: [] }
        }
        allow(described_class).to receive(:load_role_data).with(:test_role).and_return(role_data)

        role = described_class.get(:test_role)

        expect(role.permissions(:project)).to contain_exactly(:create_issue, :read_epic, :read_epic_board)
      end

      it 'only loads the role once for circular inheritance without infinite recursion' do
        role_a = {
          name: 'role_a', inherits_from: [:role_b],
          project: { raw_permissions: [:permission_1], permissions: [] },
          group: { raw_permissions: [], permissions: [] }
        }
        role_b = {
          name: 'role_b', inherits_from: [:role_a],
          project: { raw_permissions: [:permission_2], permissions: [] },
          group: { raw_permissions: [], permissions: [] }
        }

        allow(described_class).to receive(:load_role_data).with(:role_a).and_return(role_a)
        allow(described_class).to receive(:load_role_data).with(:role_b).and_return(role_b)

        expect(described_class.get(:role_a).permissions(:project)).to contain_exactly(:permission_1, :permission_2)
      end
    end

    context 'when scoped to :group' do
      it 'returns only direct group permissions for a role with no inherited roles' do
        role = described_class.get(:guest)

        expect(role.permissions(:group)).to contain_exactly(:read_group, :read_release)
      end

      it 'returns all group permissions for a role including inherited permissions' do
        role = described_class.get(:reporter)

        expect(role.permissions(:group)).to contain_exactly(
          :read_group, :read_release, # from guest
          :read_package, :read_prometheus # from reporter
        )
      end

      it 'returns all group permissions recursively for roles with multi-level inheritance' do
        role = described_class.get(:developer)

        expect(role.permissions(:group)).to contain_exactly(
          :read_group, :read_release, # from guest
          :read_package, :read_prometheus, # from reporter
          :create_package, :read_cluster_agent # from developer
        )
      end

      it 'expands assignable permissions so group permissions include raw and expanded assignable ones' do
        assignable = instance_double(Authz::PermissionGroups::Assignable, permissions: [:read_epic, :read_epic_board])
        allow(Authz::PermissionGroups::Assignable).to receive(:get).with(:read_work_item).and_return(assignable)

        role_data = {
          name: 'test_role', inherits_from: [],
          project: { raw_permissions: [], permissions: [] },
          group: { raw_permissions: [:read_group], permissions: [:read_work_item] }
        }
        allow(described_class).to receive(:load_role_data).with(:test_role).and_return(role_data)

        role = described_class.get(:test_role)

        expect(role.permissions(:group)).to contain_exactly(:read_group, :read_epic, :read_epic_board)
      end
    end

    context 'with an invalid scope' do
      it 'raises an ArgumentError' do
        role = described_class.get(:guest)

        expect { role.permissions(:invalid) }.to raise_error(ArgumentError, /Invalid scope: invalid/)
      end
    end

    context 'when scoped to :all' do
      it 'returns combined project and group permissions' do
        role_data = {
          name: 'test_role', inherits_from: [],
          project: { raw_permissions: [:read_issue], permissions: [] },
          group: { raw_permissions: [:read_group], permissions: [] }
        }
        allow(described_class).to receive(:load_role_data).with(:test_role).and_return(role_data)

        role = described_class.get(:test_role)

        expect(role.permissions(:all)).to contain_exactly(:read_issue, :read_group)
      end
    end
  end

  describe '#direct_permissions' do
    it 'does not include inherited permissions' do
      role = described_class.get(:reporter)

      expect(role.direct_permissions(:project)).to contain_exactly(:read_code, :download_code)
      expect(role.direct_permissions(:project)).not_to include(:read_issue, :create_issue)
    end

    it 'expands assignable permissions' do
      assignable = instance_double(Authz::PermissionGroups::Assignable, permissions: [:read_epic, :read_epic_board])
      allow(Authz::PermissionGroups::Assignable).to receive(:get).with(:read_work_item).and_return(assignable)

      role_data = {
        name: 'test_role', inherits_from: [],
        project: { raw_permissions: [:create_issue], permissions: [:read_work_item] },
        group: { raw_permissions: [], permissions: [] }
      }
      allow(described_class).to receive(:load_role_data).with(:test_role).and_return(role_data)

      role = described_class.get(:test_role)

      expect(role.direct_permissions(:project)).to contain_exactly(:create_issue, :read_epic, :read_epic_board)
    end

    context 'when scoped to :project' do
      it 'returns only permissions defined directly in the role YAML' do
        role = described_class.get(:developer)

        expect(role.direct_permissions(:project)).to contain_exactly(:push_code, :create_pipeline)
      end
    end

    context 'when scoped to :group' do
      it 'returns only permissions defined directly in the role YAML' do
        role = described_class.get(:developer)

        expect(role.direct_permissions(:group)).to contain_exactly(:create_package, :read_cluster_agent)
      end
    end

    context 'when scoped to :all' do
      it 'returns combined direct permissions from all scopes' do
        role = described_class.get(:developer)

        expect(role.direct_permissions(:all)).to contain_exactly(
          :push_code, :create_pipeline, :create_package, :read_cluster_agent
        )
      end
    end

    context 'with an invalid scope' do
      it 'raises an ArgumentError' do
        role = described_class.get(:guest)

        expect { role.direct_permissions(:invalid) }.to raise_error(ArgumentError, /Invalid scope: invalid/)
      end
    end
  end
end
