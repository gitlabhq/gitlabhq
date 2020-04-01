# frozen_string_literal: true

module NonExistingRecordsHelpers
  # Max value for PG `serial` type: https://www.postgresql.org/docs/12/datatype-numeric.html
  ACTIVE_MODEL_INTEGER_MAX = 2147483647

  def non_existing_record_id
    ACTIVE_MODEL_INTEGER_MAX
  end
  alias_method :non_existing_record_iid, :non_existing_record_id
  alias_method :non_existing_record_access_level, :non_existing_record_id
end
