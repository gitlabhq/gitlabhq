# frozen_string_literal: true
require "graphql/dataloader/source"

module GraphQL
  class Dataloader
    class ActiveRecordSource < GraphQL::Dataloader::Source
      def initialize(model_class, find_by: model_class.primary_key)
        @model_class = model_class
        @find_by = find_by
        @type_for_column = @model_class.type_for_attribute(@find_by)
      end

      def load(requested_key)
        casted_key = @type_for_column.cast(requested_key)
        super(casted_key)
      end

      def fetch(record_ids)
        records = @model_class.where(@find_by => record_ids)
        record_lookup = {}
        records.each { |r| record_lookup[r.public_send(@find_by)] = r }
        record_ids.map { |id| record_lookup[id] }
      end
    end
  end
end
