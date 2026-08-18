# frozen_string_literal: true

# Reads audit events across the four scoped audit event tables.
#
# `Gitlab::Audit::Auditor` no longer writes to the legacy `audit_events` table.
# Events are persisted to `project_audit_events`, `group_audit_events`,
# `user_audit_events` and `instance_audit_events` instead, so specs that used to
# assert against `AuditEvent` read through this module and stay agnostic about
# which table an event landed in.
#
# Query methods return plain Arrays of scoped audit event records ordered by id.
# The scoped tables share `audit_events_id_seq`, so ids are comparable across
# tables and the ordering matches what the legacy table used to return. Loading
# every row is fine here because these tables hold a handful of records per
# example.
module AuditEventReader
  ENTITY_TYPE_TO_MODEL = {
    'Project' => 'AuditEvents::ProjectAuditEvent',
    'Group' => 'AuditEvents::GroupAuditEvent',
    'User' => 'AuditEvents::UserAuditEvent',
    'Gitlab::Audit::InstanceScope' => 'AuditEvents::InstanceAuditEvent'
  }.freeze

  # The column each scoped table uses to reference its entity. Instance events
  # are not scoped to a record and so have no equivalent column.
  ENTITY_ID_COLUMNS = {
    'AuditEvents::ProjectAuditEvent' => :project_id,
    'AuditEvents::GroupAuditEvent' => :group_id,
    'AuditEvents::UserAuditEvent' => :user_id
  }.freeze

  class << self
    def models
      ENTITY_TYPE_TO_MODEL.values.map(&:constantize)
    end

    def count
      models.sum(&:count)
    end

    def maximum(column)
      models.filter_map { |model| model.maximum(column) }.max
    end

    def all
      order(:id)
    end

    # Accepts either a column name (`order(:id)`) or a column/direction pair
    # (`order(id: :desc)`), matching the ActiveRecord forms these specs use.
    def order(column)
      column, direction = column.is_a?(Hash) ? column.first : [column, :asc]

      sorted = models.flat_map(&:all).sort_by { |record| record.public_send(column) }
      direction.to_sym == :desc ? sorted.reverse : sorted
    end

    def last(limit = nil)
      limit ? all.last(limit) : all.last
    end

    def first(limit = nil)
      limit ? all.first(limit) : all.first
    end

    def second
      all[1]
    end

    def find_by(...)
      where(...).first
    end

    def by_entity_id(entity_id)
      where(entity_id: entity_id)
    end

    def by_entity(entity_type, entity_id)
      where(entity_type: entity_type, entity_id: entity_id)
    end

    # Accepts the same arguments as `ActiveRecord::QueryMethods#where` and runs
    # them against every scoped model. `entity_type` and `entity_id` are not
    # columns on the scoped tables, so they are translated into a model choice
    # and that model's entity column respectively.
    def where(*args)
      conditions = args.last.is_a?(Hash) ? args.pop : {}
      entity_type = conditions[:entity_type]
      entity_id = conditions[:entity_id]
      conditions = conditions.except(:entity_type, :entity_id)

      scoped_models(entity_type).flat_map do |model|
        # `where` with no arguments returns a WhereChain rather than a relation.
        scope = args.any? ? model.where(*args) : model.all
        scope = scope.where(conditions) if conditions.any?
        scope = apply_entity_id(model, scope, entity_id) unless entity_id.nil?

        scope ? scope.to_a : []
      end.sort_by(&:id)
    end

    private

    def scoped_models(entity_type)
      return models if entity_type.nil?

      model = ENTITY_TYPE_TO_MODEL[entity_type.to_s]

      model ? [model.constantize] : []
    end

    # Returns nil when the model cannot hold the requested entity, so the caller
    # skips it rather than matching every row in that table.
    def apply_entity_id(model, scope, entity_id)
      column = ENTITY_ID_COLUMNS[model.name]

      column ? scope.where(column => entity_id) : nil
    end
  end
end
