# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe NullifyUsersRole do
  let(:users) { table(:users) }

  before do
    allow(Gitlab).to receive(:com?).and_return(true)

    users.create!(role: 0, updated_at: '2019-11-04 12:08:00', projects_limit: 0, email: '1')
    users.create!(role: 1, updated_at: '2019-11-04 12:08:00', projects_limit: 0, email: '2')
    users.create!(role: 0, updated_at: '2019-11-06 12:08:00', projects_limit: 0, email: '3')

    migrate!
  end

  it 'nullifies the role of the user with updated_at < 2019-11-05 12:08:00 and a role of 0' do
    expect(users.where(role: nil).count).to eq(1)
    expect(users.find_by(role: nil).email).to eq('1')
  end

  it 'leaves the user with role of 1' do
    expect(users.where(role: 1).count).to eq(1)
    expect(users.find_by(role: 1).email).to eq('2')
  end

  it 'leaves the user with updated_at > 2019-11-05 12:08:00' do
    expect(users.where(role: 0).count).to eq(1)
    expect(users.find_by(role: 0).email).to eq('3')
  end
end
