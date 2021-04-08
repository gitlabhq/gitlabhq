# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::PhabricatorImport::Cache::Map, :clean_gitlab_redis_cache do
  let_it_be(:project) { create(:project) }

  let(:redis) { Gitlab::Redis::Cache }

  subject(:map) { described_class.new(project) }

  describe '#get_gitlab_model' do
    it 'returns nil if there was nothing cached for the phabricator id' do
      expect(map.get_gitlab_model('does not exist')).to be_nil
    end

    it 'returns the object if it was set in redis' do
      issue = create(:issue, project: project)
      set_in_redis('exists', issue)

      expect(map.get_gitlab_model('exists')).to eq(issue)
    end

    it 'extends the TTL for the cache key' do
      set_in_redis('extend', create(:issue, project: project)) do |redis|
        redis.expire(cache_key('extend'), 10.seconds.to_i)
      end

      map.get_gitlab_model('extend')

      ttl = redis.with { |redis| redis.ttl(cache_key('extend')) }

      expect(ttl).to be > 10.seconds
    end

    it 'sets the object in redis once if a block was given and nothing was cached' do
      issue = create(:issue, project: project)

      expect(map.get_gitlab_model('does not exist') { issue }).to eq(issue)

      expect { |b| map.get_gitlab_model('does not exist', &b) }
        .not_to yield_control
    end

    it 'does not cache `nil` objects' do
      expect(map).not_to receive(:set_gitlab_model)

      map.get_gitlab_model('does not exist') { nil }
    end
  end

  describe '#set_gitlab_model' do
    around do |example|
      freeze_time { example.run }
    end

    it 'sets the class and id in redis with a ttl' do
      issue = create(:issue, project: project)

      map.set_gitlab_model(issue, 'it is set')

      set_data, ttl = redis.with do |redis|
        redis.pipelined do |p|
          p.mapped_hmget(cache_key('it is set'), :classname, :database_id)
          p.ttl(cache_key('it is set'))
        end
      end

      expect(set_data).to eq({ classname: 'Issue', database_id: issue.id.to_s })
      expect(ttl).to be_within(1.second).of(Gitlab::Import::StuckImportJob::IMPORT_JOBS_EXPIRATION)
    end
  end

  def set_in_redis(key, object)
    redis.with do |redis|
      redis.mapped_hmset(cache_key(key),
                         { classname: object.class, database_id: object.id })
      yield(redis) if block_given?
    end
  end

  def cache_key(phabricator_id)
    subject.__send__(:cache_key_for_phabricator_id, phabricator_id)
  end
end
