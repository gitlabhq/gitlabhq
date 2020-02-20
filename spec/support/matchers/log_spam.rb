# frozen_string_literal: true

# This matcher checks if one spam log with provided attributes was created
# during the block evocation.
#
# Example:
#
# expect { create_issue }.to log_spam(key1: value1, key2: value2)

RSpec::Matchers.define :log_spam do |expected|
  match do |block|
    @existing_logs_count = SpamLog.count

    block.call

    @new_logs_count = SpamLog.count
    @last_spam_log = SpamLog.last

    expect(@new_logs_count - @existing_logs_count).to eq 1
    expect(@last_spam_log).to have_attributes(expected)
  end

  description do
    count = @new_logs_count - @existing_logs_count

    if count == 1
      keys = expected.keys.map(&:to_s)
      actual = @last_spam_log.attributes.slice(*keys)
      "create a spam log with #{expected} attributes. #{actual} created instead."
    else
      "create exactly 1 spam log with #{expected} attributes. #{count} spam logs created instead."
    end
  end

  supports_block_expectations
end

# This matcher checks that the last spam log
# has the attributes provided.
# The spam log does not have to be created during the block evocation.
# The number of total spam logs just has to be more than one.
#
# Example:
#
# expect { create_issue }.to have_spam_log(key1: value1, key2: value2)

RSpec::Matchers.define :have_spam_log do |expected|
  match do |block|
    block.call

    @total_logs_count = SpamLog.count
    @latest_spam_log = SpamLog.last
    expect(SpamLog.last).to have_attributes(expected)
  end

  description do
    if @total_logs_count > 0
      keys = expected.keys.map(&:to_s)
      actual = @latest_spam_log.attributes.slice(*keys)
      "the last spam log to have #{expected} attributes. Last spam log has #{actual} attributes instead."
    else
      "there to be a spam log, but there are no spam logs."
    end
  end

  supports_block_expectations
end
