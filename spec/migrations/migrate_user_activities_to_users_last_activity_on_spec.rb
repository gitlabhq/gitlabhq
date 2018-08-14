# encoding: utf-8

require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20170324160416_migrate_user_activities_to_users_last_activity_on.rb')

describe MigrateUserActivitiesToUsersLastActivityOn, :clean_gitlab_redis_shared_state, :delete do
  let(:migration) { described_class.new }
  let!(:user_active_1) { create(:user) } # rubocop:disable RSpec/FactoriesInMigrationSpecs
  let!(:user_active_2) { create(:user) } # rubocop:disable RSpec/FactoriesInMigrationSpecs

  def record_activity(user, time)
    Gitlab::Redis::SharedState.with do |redis|
      redis.zadd(described_class::USER_ACTIVITY_SET_KEY, time.to_i, user.username)
    end
  end

  around do |example|
    Timecop.freeze { example.run }
  end

  before do
    record_activity(user_active_1, described_class::TIME_WHEN_ACTIVITY_SET_WAS_INTRODUCED + 2.months)
    record_activity(user_active_2, described_class::TIME_WHEN_ACTIVITY_SET_WAS_INTRODUCED + 3.months)
    mute_stdout { migration.up }
  end

  describe '#up' do
    it 'fills last_activity_on from the legacy Redis Sorted Set' do
      expect(user_active_1.reload.last_activity_on).to eq((described_class::TIME_WHEN_ACTIVITY_SET_WAS_INTRODUCED + 2.months).to_date)
      expect(user_active_2.reload.last_activity_on).to eq((described_class::TIME_WHEN_ACTIVITY_SET_WAS_INTRODUCED + 3.months).to_date)
    end
  end

  describe '#down' do
    it 'sets last_activity_on to NULL for all users' do
      mute_stdout { migration.down }

      expect(user_active_1.reload.last_activity_on).to be_nil
      expect(user_active_2.reload.last_activity_on).to be_nil
    end
  end

  def mute_stdout
    orig_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout = orig_stdout
  end
end
