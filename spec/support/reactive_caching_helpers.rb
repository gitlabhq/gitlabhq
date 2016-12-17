module ReactiveCachingHelpers
  def reactive_cache_key(subject, *qualifiers)
    ([subject.class.reactive_cache_key.call(subject)].flatten + qualifiers).join(':')
  end

  def stub_reactive_cache(subject = nil, data = nil)
    allow(ReactiveCachingWorker).to receive(:perform_async)
    allow(ReactiveCachingWorker).to receive(:perform_in)
    write_reactive_cache(subject, data) if data
  end

  def read_reactive_cache(subject)
    Rails.cache.read(reactive_cache_key(subject))
  end

  def write_reactive_cache(subject, data)
    start_reactive_cache_lifetime(subject)
    Rails.cache.write(reactive_cache_key(subject), data)
  end

  def reactive_cache_alive?(subject)
    Rails.cache.read(reactive_cache_key(subject, 'alive'))
  end

  def invalidate_reactive_cache(subject)
    Rails.cache.delete(reactive_cache_key(subject, 'alive'))
  end

  def start_reactive_cache_lifetime(subject)
    Rails.cache.write(reactive_cache_key(subject, 'alive'), true)
  end

  def expect_reactive_cache_update_queued(subject)
    expect(ReactiveCachingWorker).
      to receive(:perform_in).
      with(subject.class.reactive_cache_refresh_interval, subject.class, subject.id)
  end
end
