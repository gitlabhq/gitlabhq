# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe ChangeDefaultValueOnPasswordLastChangedAtToUserDetails, :migration, feature_category: :user_profile do
  let(:namespace) { table(:namespaces).create!(name: 'user', path: 'user') }
  let(:users) { table(:users) }
  let(:user_details) { table(:user_details) }

  it 'correctly migrates up and down' do
    user = create_user!(email: '1234@abc')
    user_details.create!(user_id: user.id, provisioned_by_group_id: namespace.id)

    expect(UserDetail.find_by(user_id: user.id).password_last_changed_at).to be_nil

    migrate!

    user = create_user!(email: 'abc@1234')
    user_details.create!(user_id: user.id, provisioned_by_group_id: namespace.id)

    expect(UserDetail.find_by(user_id: user.id).password_last_changed_at).not_to be_nil
  end

  private

  def create_user!(name: "Example User", email: "user@example.com", user_type: nil)
    users.create!(
      name: name,
      email: email,
      username: name,
      projects_limit: 0,
      user_type: user_type,
      confirmed_at: Time.current
    )
  end
end
