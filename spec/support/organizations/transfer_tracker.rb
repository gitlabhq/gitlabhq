# frozen_string_literal: true

module Gitlab
  module Organizations
    class TransferTracker
      attr_reader :tracked_table_locations

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
        return unless stmt.try(:update_stmt)

        update_stmt = stmt.update_stmt
        table_name = update_stmt.relation.relname

        set_columns = update_stmt.target_list.map { |target| target.res_target.name }
        return unless set_columns.include?('organization_id')

        @mutex.synchronize do
          record_table(table_name, location) if org_sharded_table?(table_name)
          partition_table_names(table_name).each { |name| record_table(name, location) }
        end
      rescue StandardError => e
        @exception ||= e
        warn("TransferTracker error: #{e.message}")
      end

      def record_table(table_name, location)
        @tracked_table_locations[table_name] ||= Set.new
        @tracked_table_locations[table_name] << location
      end

      def org_sharded_table?(table_name)
        entry = Gitlab::Database::Dictionary.entry(table_name)
        entry&.sharding_key.is_a?(Hash) && entry.sharding_key.key?('organization_id')
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
          e.sharding_key.is_a?(Hash) && e.sharding_key.key?('organization_id')
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

      def find_service_caller_location
        return unless @service_path_pattern

        location = caller_locations(0, 50).find { |loc| loc.path.match?(@service_path_pattern) }
        return unless location

        "#{location.path}:#{location.lineno}"
      end
    end
  end
end
