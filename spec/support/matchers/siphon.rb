# frozen_string_literal: true

RSpec::Matchers.define :be_a_siphon_of do |pg_table|
  match do |ch_table|
    matching_field_names_and_type?(pg_table, ch_table)
  end
end

RSpec::Matchers.define :match_database_schema do |table_config|
  match do |content|
    @database = content['database']
    @gitlab_schema = table_config['gitlab_schema']
    @db_config = Gitlab::Database.all_database_connections[@database]

    @db_config.present? && @db_config.gitlab_schemas.include?(@gitlab_schema.to_sym)
  end

  failure_message do
    if @db_config.nil?
      "expected database '#{@database}' to be 'main', 'sec', or 'ci'"
    else
      "expected database '#{@database}' to have gitlab_schema '#{@gitlab_schema}', it was #{@db_config.gitlab_schemas}"
    end
  end
end

RSpec::Matchers.define :ignore_sensitive_and_encrypted_columns do |table_config, skipped_columns|
  match do |content|
    @ignored_columns = Array(content['ignored_columns']).to_set
    @skipped_columns = Array(skipped_columns).to_set
    @errors = []

    table_config['classes'].each do |class_name|
      # Some models are only defined in EE
      model = class_name.safe_constantize
      next unless model

      # Use connection.columns instead of model.column_names because the latter
      # respects ignored_columns, which would exclude the very columns we need
      # to validate in the ignored_columns check below.
      postgresql_columns = model.connection.columns(model.table_name).map(&:name)

      # Check if all ignored columns actually exist in PG
      missing_in_pg = @ignored_columns - postgresql_columns.to_set
      unless missing_in_pg.empty?
        @errors << "ignored_columns contains fields not present in PG: #{missing_in_pg.to_a.join(', ')}"
      end

      # Check token_authenticatable_fields
      if model.respond_to?(:token_authenticatable_fields)
        token_fields = Array(model.token_authenticatable_fields).map(&:to_s).to_set
        # token columns might have _encrypted suffix in the DB
        without_encrypted_suffix = @ignored_columns.map { |c| c.gsub('_encrypted', '') }
        missing = token_fields - @ignored_columns - without_encrypted_suffix
        unless missing.empty?
          @errors << "missing token_authenticatable_fields in ignored_columns: #{missing.to_a.join(', ')}"
        end
      end

      # Check encrypted_attributes
      if model.respond_to?(:encrypted_attributes)
        encrypted_attributes = Array(model.encrypted_attributes).map(&:to_s).to_set
        missing = encrypted_attributes - @ignored_columns
        @errors << "missing encrypted_attributes in ignored_columns: #{missing.to_a.join(', ')}" unless missing.empty?
      end

      # Check _token and _html columns
      postgresql_columns.each do |column|
        next unless column.include?('_token') || column.include?('_html') || column.include?('secret')
        next if @skipped_columns.include?(column)
        next if @ignored_columns.include?(column)

        @errors << "column '#{column}' looks sensitive or large but is not in ignored_columns"
      end
    end

    @errors.empty?
  end

  failure_message do |content|
    "expected #{content['table']} to ignore sensitive and encrypted columns, but:\n  " + @errors.join("\n  ")
  end
end

RSpec::Matchers.define :have_correct_reconcile_config do
  match do |content|
    @errors = []

    target = Array(content['replication_targets']).first
    next true unless target&.key?('reconcile')

    reconcile = target['reconcile']

    doc_path = Rails.root.join('db', 'docs', "#{content['table']}.yml")
    unless File.exist?(doc_path)
      @errors << "db/docs/#{content['table']}.yml not found for reconcile validation"
      next false
    end

    doc = YAML.safe_load_file(doc_path)
    sharding_keys = doc['sharding_key'] || doc['desired_sharding_key']
    expected_columns = sharding_keys.keys&.sort || []

    if expected_columns.empty?
      @errors << "no sharding_key found in db/docs/#{content['table']}.yml"
    else
      actual_columns = Array(reconcile['expression_key_columns'])
      if actual_columns != expected_columns
        @errors << "expression_key_columns [#{actual_columns.join(', ')}] does not match " \
          "sharding_key columns [#{expected_columns.join(', ')}] from db/docs/#{content['table']}.yml"
      end
    end

    @errors.empty?
  end

  failure_message do |content|
    "expected #{content['table']} to have correct reconcile config, but:\n  " + @errors.join("\n  ")
  end
end

RSpec::Matchers.define :have_correct_replication_target do |clickhouse_table_names|
  def ch_primary_keys(table)
    query =
      <<~SQL
        SELECT primary_key
        FROM system.tables
        WHERE database = '#{ch_database_name}' AND name = '#{table}'
      SQL

    row = ClickHouse::Client.select(query, :main).first
    raise "Table not found: #{table}" unless row

    row['primary_key']
      .split(',')
      .map(&:strip)
  end

  def ch_column_names(ch_table)
    query =
      <<~SQL
        SELECT name
        FROM system.columns
        WHERE table = '#{ch_table}' AND database = '#{ch_database_name}';
      SQL

    ClickHouse::Client.select(query, :main).pluck("name")
  end

  match do |content|
    next true unless content.has_key?('replication_targets')

    @errors = []
    replication_targets = Array(content['replication_targets'])
    if replication_targets.size > 1
      @errors << "expected exactly 0 or 1 replication target, got #{replication_targets.size}"
    end

    target = replication_targets.first
    if target['name'] != 'clickhouse_main'
      @errors << "expected replication target name to be 'clickhouse_main', got '#{target['name']}'"
    end

    unless clickhouse_table_names.include?(target['target'])
      @errors << "target ClickHouse table '#{target['target']}' does not exist"
    end

    if target['dedup_by_table'] && clickhouse_table_names.exclude?(target['dedup_by_table'])
      @errors << "dedup_by_table '#{target['dedup_by_table']}' does not exist"
    end

    # If dedup_by_table config is present, we must inspect that table for matching primary keys
    clickhouse_table = target['dedup_by_table'] || target['target']

    postgresql_primary_keys = ApplicationRecord.connection.primary_keys(content['table'])
    clickhouse_primary_keys = ch_primary_keys(clickhouse_table)
    if target['dedup_by']
      dedup_cols = target['dedup_by'].join(', ')
      pkeys = postgresql_primary_keys.join(', ')

      @errors << "dedup_by [#{dedup_cols}] does not match PG primary keys [#{pkeys}]" if dedup_cols != pkeys

      if clickhouse_primary_keys.last(postgresql_primary_keys.length) != postgresql_primary_keys
        @errors << "the ClickHouse primary keys (#{clickhouse_primary_keys.join(', ')}) don't match or end with " \
          "the PostgreSQL table's primary keys (#{postgresql_primary_keys.join(', ')})"
      end
    elsif clickhouse_primary_keys != postgresql_primary_keys
      @errors << "the ClickHouse primary keys (#{clickhouse_primary_keys.join(', ')}) don't match with " \
        "the PostgreSQL table's primary keys (#{postgresql_primary_keys.join(', ')})"
    end

    lookup_table = target['dedup_by_columns_lookup_table']
    if lookup_table
      if clickhouse_table_names.exclude?(lookup_table)
        @errors << "dedup_by_columns_lookup_table '#{lookup_table}' does not exist"
      else
        lookup_primary_keys = ch_primary_keys(lookup_table)
        if lookup_primary_keys.first(postgresql_primary_keys.length) != postgresql_primary_keys
          @errors << "the ClickHouse lookup table '#{lookup_table}' primary keys " \
            "(#{lookup_primary_keys.join(', ')}) don't start with the PostgreSQL table's primary keys " \
            "(#{postgresql_primary_keys.join(', ')})"
        end
      end
    end

    Array(target['refresh_on_change']).each do |roc|
      target_identifier = roc['target_stream_identifier']
      target_path = Rails.root.join('db', 'siphon', 'tables', "#{target_identifier}.yml")
      if roc['target_stream_identifier'].empty? || !File.exist?(target_path)
        @errors << "target table/stream (#{target_path}) is not configured"
      end

      target_keys = Array(roc['target_keys'])

      target_postgresql_pks = ApplicationRecord.connection.primary_keys(roc['target_stream_identifier'])
      if target_postgresql_pks != target_keys
        @errors << "refresh_on_change.target_keys must match with the PostgreSQL primary keys of #{target_identifier}"
      end

      source_keys = Array(roc['source_keys'])
      if source_keys.size != target_keys.size
        @errors << "refresh_on_change.source_keys (#{source_keys.join(', ')}) should have the same " \
          "size as refresh_on_change.target_keys (#{target_keys.join(', ')})"
      end

      column_names = ch_column_names(target['target'])
      source_keys.each do |key|
        unless column_names.include?(key)
          @errors << "ClickHouse table '#{target['target']}' doesn't contain '#{key}' column"
        end
      end
    end

    @errors << "priority must be a number, got: '#{target['priority']}'" unless (target['priority'] || 1).is_a?(Numeric)

    @errors.empty?
  end

  failure_message do |content|
    "expected #{content['table']} to have correct replication target, but:\n  " + @errors.join("\n  ")
  end
end
