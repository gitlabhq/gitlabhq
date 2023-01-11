# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubGistsImport::Status, :clean_gitlab_redis_cache, feature_category: :importers do
  subject(:import_status) { described_class.new(user.id) }

  let_it_be(:user) { create(:user) }
  let(:key) { "gitlab:github-gists-import:#{user.id}" }

  describe '#start!' do
    it 'expires the key' do
      import_status.start!

      Gitlab::Redis::SharedState.with do |redis|
        expect(redis.get(key)).to eq('started')
      end
    end
  end

  describe '#fail!' do
    it 'sets failed status' do
      import_status.fail!

      Gitlab::Redis::SharedState.with do |redis|
        expect(redis.get(key)).to eq('failed')
      end
    end
  end

  describe '#finish!' do
    it 'sets finished status' do
      import_status.finish!

      Gitlab::Redis::SharedState.with do |redis|
        expect(redis.get(key)).to eq('finished')
      end
    end
  end

  describe '#started?' do
    before do
      Gitlab::Redis::SharedState.with { |redis| redis.set(key, 'started') }
    end

    it 'checks if status is started' do
      expect(import_status.started?).to eq(true)
    end
  end
end
