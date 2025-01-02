# frozen_string_literal: true

RSpec::Matchers.define :validate_index_limit do |offences_type|
  match do |actual|
    expect(actual).to be_empty
  end

  failure_message do
    message = case offences_type
              when :new
                "The following tables exceed the maximum allowed number of indexes, " \
                  "please reconsider adding new index or add them the list of existing offences: #{actual.join(', ')}"
              when :corrected
                "The following tables no longer exceed the maximum allowed number of indexes, " \
                  "please remove them from the list of existing offences: #{actual.join(', ')}"
              when :outdated
                "The following tables are listed as exceeding the maximum allowed number of indexes, but " \
                  "the number of indexes is oudated, please update the list of existing offences: #{actual.join(', ')}"
              end

    <<~FAILURE_MESSAGE
      #{message}

      See https://docs.gitlab.com/ee/development/database/adding_database_indexes.html#maintenance-overhead for more information.
    FAILURE_MESSAGE
  end
end
