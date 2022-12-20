# frozen_string_literal: true

module BatchDestroyDependentAssociationsHelper
  private

  def delete_in_batches_regexps(table, column, resource, items, batch_size: 1000)
    # rubocop:disable Layout/LineLength
    select_query = %r{^SELECT "#{table}".* FROM "#{table}" WHERE.* "#{table}"."#{column}" = #{resource.id}.*ORDER BY "#{table}"."id" ASC LIMIT #{batch_size}}
    # rubocop:enable Layout/LineLength

    [select_query] + items.map { |item| %r{^DELETE FROM "#{table}" WHERE "#{table}"."id" = #{item.id}} }
  end
end
