# frozen_string_literal: true

EXPECTED_SMALLINT_LIMIT = 2

RSpec::Matchers.define :use_smallint_for_enums do |enums|
  match do |actual|
    @failing_enums = enums.select do |enum|
      enum_type = actual.type_for_attribute(enum)
      actual_limit = enum_type.send(:subtype).limit
      actual_limit != EXPECTED_SMALLINT_LIMIT
    end
    @failing_enums.empty?
  end

  failure_message do
    <<~FAILURE_MESSAGE
      Expected #{actual.name} enums: #{failing_enums.join(', ')} to use the smallint type.

      The smallint type is 2 bytes which is more than sufficient for an enum.
      Using the smallint type would help us save space in the database.
      To fix this, please add `limit: 2` in the migration file, for example:

      def change
        add_column :ci_job_artifacts, :file_format, :integer, limit: 2
      end
    FAILURE_MESSAGE
  end

  def failing_enums
    @failing_enums ||= []
  end
end
