# frozen_string_literal: true

require 'fast_spec_helper'
require 'puma'
require 'puma/thread_pool'

RSpec.describe Gitlab::Patch::PumaIoThreadExit, feature_category: :knowledge_graph do
  it 'lowers the thread count when an extra IO thread exits' do
    release = Mutex.new
    release.lock
    started = Queue.new
    pool = Puma::ThreadPool.new('tst', { min_threads: 0, max_threads: 2, max_io_threads: 2 }) do |processor, _work|
      processor.mark_as_io_thread!
      started << true
      release.synchronize { nil }
    end
    pool.singleton_class.prepend(described_class)

    4.times { pool << true }
    4.times { started.pop(timeout: 2) }
    expect(pool.spawned).to eq(4)

    release.unlock
    Timeout.timeout(2) { sleep 0.01 until pool.spawned == 2 }

    expect(pool.spawned).to eq(2)
  ensure
    release.unlock if release&.owned?
    pool&.shutdown(1)
  end
end
