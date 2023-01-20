# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe AddIndexOnPasswordLastChangedAtToUserDetails, :migration, feature_category: :user_profile do
  let(:index_name) { 'index_user_details_on_password_last_changed_at' }

  it 'correctly migrates up and down' do
    expect(subject).not_to be_index_exists_by_name(:user_details, index_name)

    migrate!

    expect(subject).to be_index_exists_by_name(:user_details, index_name)
  end
end
