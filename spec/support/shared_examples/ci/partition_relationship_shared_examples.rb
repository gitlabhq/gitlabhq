# frozen_string_literal: true

RSpec.shared_examples 'including partition key for relation' do |relation_name|
  it "includes partition_id in the query for record's relation #{relation_name}" do
    reflection = subject.class.reflections[relation_name.to_s]
    collection_or_self = reflection.collection? ? :to_a : :self

    recorder = ActiveRecord::QueryRecorder.new { subject.try(relation_name).try(collection_or_self) }

    table_name = reflection.klass.table_name
    foreign_key_name = reflection.options[:foreign_key]
    partition_foreign_key_name = reflection.options[:partition_foreign_key]

    key_name, key_value, partition_key_name, partition_key_value =
      case reflection
      # For `belongs_to` association, we will need to query the association using the foreign key in the current table.
      # This is because in a `belongs_to` relation, the current table contains a reference to the target table
      when ActiveRecord::Reflection::BelongsToReflection
        [:id, subject.try(foreign_key_name), :partition_id, subject.try(partition_foreign_key_name)]
      # For all the other associations such as `has_many`,
      # we will need to query the association using the `id` and `partition_id` of the current table.
      # This is because the target table references the current table.
      else
        [foreign_key_name, subject.id, partition_foreign_key_name, subject.partition_id]
      end

    # Positive lookahead to ensure the string contains this expression e.g. `"p_ci_builds"."id" = 1`
    expression_matching_key = %{(?=.*"#{table_name}"."#{key_name}" = #{key_value})}
    # Positive lookahead to ensure the string contains this expression e.g. `"p_ci_builds"."partition_id" = 102` as well
    expression_matching_partition_key =
      %{(?=.*"#{table_name}"."#{partition_key_name}" = #{partition_key_value})}
    expect(recorder.log)
      .to include(/\A#{expression_matching_key}#{expression_matching_partition_key}.*\z/)
  end
end
