# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::ErrorTracking::LogFormatter do
  let(:exception) { StandardError.new('boom') }
  let(:context_payload) do
    {
      server: 'local-hostname-of-the-server',
      user: {
        ip_address: '127.0.0.1',
        username: 'root'
      },
      tags: {
        locale: 'en',
        feature_category: 'category_a'
      },
      extra: {
        some_other_info: 'other_info',
        sidekiq: {
          'class' => 'HelloWorker',
          'args' => ['senstive string', 1, 2],
          'another_field' => 'field'
        }
      }
    }
  end

  before do
    Raven.context.user[:user_flag] = 'flag'
    Raven.context.tags[:shard] = 'catchall'
    Raven.context.extra[:some_info] = 'info'

    allow(exception).to receive(:backtrace).and_return(
      [
        'lib/gitlab/file_a.rb:1',
        'lib/gitlab/file_b.rb:2'
      ]
    )
  end

  after do
    ::Raven::Context.clear!
  end

  it 'appends error-related log fields and filters sensitive Sidekiq arguments' do
    payload = described_class.new.generate_log(exception, context_payload)

    expect(payload).to eql(
      'exception.class' => 'StandardError',
      'exception.message' => 'boom',
      'exception.backtrace' => [
        'lib/gitlab/file_a.rb:1',
        'lib/gitlab/file_b.rb:2'
      ],
      'user.ip_address' => '127.0.0.1',
      'user.username' => 'root',
      'user.user_flag' => 'flag',
      'tags.locale' => 'en',
      'tags.feature_category' => 'category_a',
      'tags.shard' => 'catchall',
      'extra.some_other_info' => 'other_info',
      'extra.some_info' => 'info',
      "extra.sidekiq" => {
        "another_field" => "field",
        "args" => ["[FILTERED]", "1", "2"],
        "class" => "HelloWorker"
      }
    )
  end
end
