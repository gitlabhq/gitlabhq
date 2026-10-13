# frozen_string_literal: true

require "spec_helper"

RSpec.describe Admin::UserSerializer do
  let_it_be(:admin) { build_stubbed(:user, :admin) }

  let(:resource) { build(:user) }

  subject { described_class.new.represent(resource, current_user: admin).keys }

  context 'when there is a single object provided', :enable_admin_mode do
    it 'contains important elements for the admin user table' do
      is_expected.to include(
        :id,
        :name,
        :created_at,
        :email,
        :username,
        :last_activity_on,
        :avatar_url,
        :note,
        :badges,
        :actions
      )
    end
  end
end
