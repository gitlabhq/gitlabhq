# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe TruncateUserFullname do
  let(:users) { table(:users) }

  let(:user_short) { create_user(name: 'abc', email: 'test_short@example.com') }
  let(:user_long) { create_user(name: 'a' * 200 + 'z', email: 'test_long@example.com') }

  def create_user(params)
    users.create!(params.merge(projects_limit: 0))
  end

  it 'truncates user full name to the first 128 characters' do
    expect { migrate! }.to change { user_long.reload.name }.to('a' * 128)
  end

  it 'does not truncate short names' do
    expect { migrate! }.not_to change { user_short.reload.name.length }
  end
end
