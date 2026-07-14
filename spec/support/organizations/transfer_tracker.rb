# frozen_string_literal: true

module Gitlab
  module Organizations
    class TransferTracker
      attr_reader :tracked_table_locations

      EXCLUDED_CALL_PATHS = [
        %r{lib/users/internal\.rb}
      ].freeze

      def initialize(service_path_pattern: nil)
        @tracked_table_locations = {}
        @subscriber = nil
        @service_path_pattern = service_path_pattern
        @exception = nil
        @mutex = Mutex.new
      end

      def track
        @tracked_table_locations = {}
        @exception = nil
        subscribe
        yield
      ensure
        unsubscribe
        raise @exception if @exception
      end

      def tracked_tables
        @tracked_table_locations.keys
      end

      private

      def subscribe
        @subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') do |*, payload|
          record_if_organization_update(payload[:sql])
        end
      end

      def unsubscribe
        ActiveSupport::Notifications.unsubscribe(@subscriber) if @subscriber
        @subscriber = nil
      end

      def record_if_organization_update(sql)
        location = find_service_caller_location
        return unless location

        parsed = PgQuery.parse(sql)
        stmt = parsed.tree.stmts.first&.stmt

        table_name, columns = extract_statement_info(stmt)
        return unless table_name && columns&.any? { |col| organization_column?(col) }

        @mutex.synchronize do
          record_table(table_name, location) if org_sharded_table?(table_name)
          partition_table_names(table_name).each { |name| record_table(name, location) }
        end
      rescue StandardError => e
        @exception ||= e
        warn("TransferTracker error: #{e.message}")
      end

      def extract_statement_info(stmt)
        if stmt.try(:update_stmt)
          update_stmt = stmt.update_stmt
          table_name = update_stmt.relation.relname
          columns = update_stmt.target_list.map { |target| target.res_target.name }
          [table_name, columns]
        elsif stmt.try(:insert_stmt)
          insert_stmt = stmt.insert_stmt
          table_name = insert_stmt.relation.relname
          columns = insert_stmt.cols.map { |col| col.res_target.name }
          [table_name, columns]
        end
      end

      def record_table(table_name, location)
        @tracked_table_locations[table_name] ||= Set.new
        @tracked_table_locations[table_name] << location
      end

      def org_sharded_table?(table_name)
        entry = Gitlab::Database::Dictionary.entry(table_name)
        return false unless entry&.sharding_key.is_a?(Hash)

        entry.sharding_key.keys.any? { |key| organization_column?(key) }
      end

      def organization_column?(column_name)
        # this will catch organization_id and snippet_organization_id
        column_name.end_with?('organization_id')
      end

      def partition_table_names(base_table_name)
        @partition_map ||= build_partition_map
        @partition_map[base_table_name] || []
      end

      def build_partition_map
        entries = org_sharded_dictionary_entries
        partitions_by_parent = fetch_partitions_by_parent(entries)

        entries.each_with_object({}) do |entry, map|
          resolve_base_table_names(entry).each do |base|
            next if base == entry.table_name

            partitions = partitions_by_parent[base] || []
            # Skip unless entry.table_name is an actual Postgres partition of the base table,
            # not just a table that happens to share a model class (e.g. Upload).
            next unless partitions.any? { |p| p.name == entry.table_name }

            (map[base] ||= []) << entry.table_name
          end
        end
      end

      def org_sharded_dictionary_entries
        Gitlab::Database::Dictionary.entries.select do |e|
          e.sharding_key.is_a?(Hash) && e.sharding_key.keys.any? { |key| organization_column?(key) }
        end
      end

      def resolve_base_table_names(entry)
        entry.classes&.filter_map do |klass_name|
          klass = klass_name.safe_constantize
          klass.table_name if klass.respond_to?(:table_name)
        end || []
      end

      def fetch_partitions_by_parent(entries)
        base_table_names = entries.flat_map { |e| resolve_base_table_names(e) }.uniq

        Gitlab::Database::PostgresPartition
          .with_parent_tables(base_table_names)
          .group_by { |p| p.parent_identifier.split('.').last }
      end

      # NOTE: INSERT ... SELECT ... statements (with no explicit column list) will not be tracked
      # because insert_stmt.cols returns an empty array. If a transfer pattern uses this form,
      # extract_statement_info will need to be extended.
      def find_service_caller_location
        return unless @service_path_pattern

        locations = caller_locations(0, 200)

        service_index = locations.index { |loc| loc.path.match?(@service_path_pattern) }
        return unless service_index

        excluded_index = locations.index { |loc| EXCLUDED_CALL_PATHS.any? { |pattern| loc.path.match?(pattern) } }
        return if excluded_index && excluded_index < service_index

        location = locations[service_index]
        "#{location.path}:#{location.lineno}"
      end
    end
  end
end
