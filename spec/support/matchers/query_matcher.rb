RSpec::Matchers.define :make_queries_matching do |matcher, expected_count = nil|
  supports_block_expectations

  match do |block|
    @counter = query_count(matcher, &block)
    if expected_count
      @counter.count == expected_count
    else
      @counter.count > 0
    end
  end

  failure_message_when_negated do |_|
    if expected_count
      "expected #{matcher} not to match #{expected_count} queries, got #{@counter.count} matches:\n\n#{@counter.inspect}"
    else
      "expected #{matcher} not to match any query, got #{@counter.count} matches:\n\n#{@counter.inspect}"
    end
  end

  failure_message do |_|
    if expected_count
      "expected #{matcher} to match #{expected_count} queries, got #{@counter.count} matches:\n\n#{@counter.inspect}"
    else
      "expected #{matcher} to match at least one query, got #{@counter.count} matches:\n\n#{@counter.inspect}"
    end
  end

  def query_count(regex, &block)
    @recorder = ActiveRecord::QueryRecorder.new(&block).log
    @recorder.select { |q| q.match(regex) }
  end
end
