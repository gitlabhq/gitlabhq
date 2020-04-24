# frozen_string_literal: true

module ReactiveCachingHelpers
  def reactive_cache_key(subject, *qualifiers)
    ([subject.class.reactive_cache_key.call(subject)].flatten + qualifiers).join(':')
  end

  def alive_reactive_cache_key(subject, *qualifiers)
    reactive_cache_key(subject, *(qualifiers + ['alive']))
  end

  def stub_reactive_cache(subject = nil, data = nil, *qualifiers)
    ReactiveCaching::WORK_TYPE.values.each do |worker|
      allow(worker).to receive(:perform_async)
      allow(worker).to receive(:perform_in)
    end

    write_reactive_cache(subject, data, *qualifiers) unless subject.nil?
  end

  def synchronous_reactive_cache(subject)
    allow(subject).to receive(:with_reactive_cache) do |*args, &block|
      block.call(subject.calculate_reactive_cache(*args))
    end
  end

  def read_reactive_cache(subject, *qualifiers)
    Rails.cache.read(reactive_cache_key(subject, *qualifiers))
  end

  def write_reactive_cache(subject, data, *qualifiers)
    start_reactive_cache_lifetime(subject, *qualifiers)
    Rails.cache.write(reactive_cache_key(subject, *qualifiers), data)
  end

  def reactive_cache_alive?(subject, *qualifiers)
    Rails.cache.read(alive_reactive_cache_key(subject, *qualifiers))
  end

  def invalidate_reactive_cache(subject, *qualifiers)
    Rails.cache.delete(alive_reactive_cache_key(subject, *qualifiers))
  end

  def start_reactive_cache_lifetime(subject, *qualifiers)
    Rails.cache.write(alive_reactive_cache_key(subject, *qualifiers), true)
  end

  def expect_reactive_cache_update_queued(subject, worker_klass: ReactiveCachingWorker)
    expect(worker_klass)
      .to receive(:perform_in)
      .with(subject.class.reactive_cache_refresh_interval, subject.class, subject.id)
  end
end
