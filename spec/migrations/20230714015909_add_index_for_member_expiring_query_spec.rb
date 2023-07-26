# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe AddIndexForMemberExpiringQuery, :migration, feature_category: :groups_and_projects do
  let(:index_name) { 'index_members_on_expiring_at_access_level_id' }

  it 'correctly migrates up and down' do
    expect(subject).not_to be_index_exists_by_name(:members, index_name)

    migrate!

    expect(subject).to be_index_exists_by_name(:members, index_name)
  end
end
