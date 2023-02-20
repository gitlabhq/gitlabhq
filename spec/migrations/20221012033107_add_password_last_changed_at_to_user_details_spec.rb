# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe AddPasswordLastChangedAtToUserDetails, feature_category: :user_profile do
  let!(:namespace) { table(:namespaces).create!(name: 'user', path: 'user') }
  let!(:users) { table(:users) }
  let!(:user) { create_user! }
  let(:user_detail) { table(:user_details).create!(user_id: user.id, provisioned_by_group_id: namespace.id) }

  describe "#up" do
    it 'allows to read password_last_changed_at' do
      migrate!

      expect(user_detail.password_last_changed_at).to eq nil
    end
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
