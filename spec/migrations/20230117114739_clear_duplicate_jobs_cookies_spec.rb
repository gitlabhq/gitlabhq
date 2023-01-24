# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe ClearDuplicateJobsCookies, :migration, feature_category: :redis do
  def with_redis(&block)
    Gitlab::Redis::Queues.with(&block)
  end

  it 'deletes duplicate jobs cookies' do
    delete = ['resque:gitlab:duplicate:blabla:1:cookie:v2', 'resque:gitlab:duplicate:foobar:2:cookie:v2']
    keep = ['resque:gitlab:duplicate:something', 'something:cookie:v2']
    with_redis { |r| (delete + keep).each { |key| r.set(key, 'value') } }

    expect(with_redis { |r| r.exists(delete + keep) }).to eq(4)

    migrate!

    expect(with_redis { |r| r.exists(delete) }).to eq(0)
    expect(with_redis { |r| r.exists(keep) }).to eq(2)
  end
end
