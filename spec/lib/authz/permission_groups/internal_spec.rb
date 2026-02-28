# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authz::PermissionGroups::Internal, feature_category: :permissions do
  before do
    stub_const("#{described_class}::BASE_PATH", 'spec/fixtures/authz/permission_groups/internal')
    # The permission definitions are memoized in the class so we need to clear them
    described_class.instance_variable_set(:@all, nil)
  end

  after do
    described_class.instance_variable_set(:@all, nil)
  end

  let(:definition_name) { 'group:archived' }

  it_behaves_like 'loadable from yaml'

  describe '.get' do
    it 'retrieves a permission group by identifier' do
      group = described_class.get('group:archived')

      expect(group).to be_present
      expect(group).to be_a(described_class)
      expect(group.permissions).to match_array(
        %i[activate_group_member add_cluster admin_achievement]
      )
    end
  end
end
