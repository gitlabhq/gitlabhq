require 'spec_helper'

describe Gitlab::UserActivities::Activity, :redis, lib: true do
  let(:username) { 'user' }
  let(:activity) { described_class.new('user', Time.new(2016, 12, 12).to_i) }

  it 'has the username' do
    expect(activity.username).to eq(username)
  end

  it 'has the last activity at' do
    expect(activity.last_activity_at).to eq('2016-12-12 00:00:00')
  end
end
