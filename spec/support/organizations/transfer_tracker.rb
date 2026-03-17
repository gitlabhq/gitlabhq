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
          @tracked_table_locations[table_name] ||= Set.new
          @tracked_table_locations[table_name] << location
        end
      rescue StandardError => e
        @exception ||= e
        warn("TransferTracker error: #{e.message}")
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
