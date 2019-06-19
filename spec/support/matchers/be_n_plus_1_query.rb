# frozen_string_literal: true

module Nplus1QueryHelpers
  DEFAULT_THRESHOLD = 3

  def with_threshold(threshold)
    @threshold = threshold
    self
  end

  def for_query(query)
    @query = query
    self
  end

  def threshold
    @threshold || DEFAULT_THRESHOLD
  end

  def occurrences
    @occurrences ||=
      if @query
        recorder.occurrences.select { |recorded, count| recorded =~ @query }
      else
        recorder.occurrences
      end
  end

  def over_threshold
    occurrences.select do |recorded, count|
      count > threshold
    end
  end

  def recorder
    @recorder ||= ActiveRecord::QueryRecorder.new(&@subject_block)
  end

  def verify_count(&block)
    @subject_block = block
    over_threshold.present?
  end

  def failure_message
    log_message = over_threshold.to_yaml
    "The following queries are executed more than #{threshold} time(s):\n#{log_message}"
  end
end

RSpec::Matchers.define :be_n_plus_1_query do
  supports_block_expectations

  include Nplus1QueryHelpers

  match do |block|
    verify_count(&block)
  end

  failure_message_when_negated do |actual|
    failure_message
  end
end
