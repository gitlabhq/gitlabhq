# frozen_string_literal: true

# Inspired by https://github.com/ljkbennett/stub_env/blob/master/lib/stub_env/helpers.rb
module StubWorker
  def stub_worker(queue:)
    Class.new do
      include Sidekiq::Worker
      sidekiq_options queue: queue
    end
  end
end
