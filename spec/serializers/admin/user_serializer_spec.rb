# frozen_string_literal: true

require "spec_helper"

RSpec.describe Admin::UserSerializer do
  let(:resource) { build(:user) }

  subject { described_class.new.represent(resource).keys }

  context 'when there is a single object provided' do
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
        :projects_count,
        :actions
      )
    end
  end
end
