# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Authz::Role, feature_category: :permissions do
  before do
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

      expect(role.permissions).to contain_exactly(:read_issue, :create_issue, :read_code, :download_code)
    end
  end

  describe '#permissions' do
    it 'returns only direct permissions for a role with no inherited roles' do
      role = described_class.get(:guest)

      expect(role.permissions).to contain_exactly(:read_issue, :create_issue)
    end

    it 'return all role permissions for a role including inherited permissions' do
      role = described_class.get(:reporter)

      expect(role.permissions).to contain_exactly(:read_issue, :create_issue, :read_code, :download_code)
    end

    it 'returns all role permissions recursively for roles with multi-level inheritance' do
      role = described_class.get(:developer)

      expect(role.permissions).to contain_exactly(
        :read_issue, :create_issue, # from guest
        :read_code, :download_code, # from reporter
        :push_code, :create_pipeline # from developer
      )
    end

    it 'expands assignable permissions so role permissions include raw permissions and expanded assignable ones' do
      assignable = instance_double(Authz::PermissionGroups::Assignable, permissions: [:read_epic, :read_epic_board])
      allow(Authz::PermissionGroups::Assignable).to receive(:get).with(:read_work_item).and_return(assignable)

      role_data = { name: 'test_role', inherits_from: [], raw_permissions: [:create_issue],
                    permissions: [:read_work_item] }
      allow(described_class).to receive(:load_role_data).with(:test_role).and_return(role_data)

      role = described_class.get(:test_role)

      expect(role.permissions).to contain_exactly(:create_issue, :read_epic, :read_epic_board)
    end

    it 'only loads the role once for circular inheritance without infinite recursion' do
      role_a = { name: 'role_a', inherits_from: [:role_b], raw_permissions: [:permission_1], permissions: [] }
      role_b = { name: 'role_b', inherits_from: [:role_a], raw_permissions: [:permission_2], permissions: [] }

      allow(described_class).to receive(:load_role_data).with(:role_a).and_return(role_a)
      allow(described_class).to receive(:load_role_data).with(:role_b).and_return(role_b)

      expect(described_class.get(:role_a).permissions).to contain_exactly(:permission_1, :permission_2)
    end
  end
end
