# frozen_string_literal: true

module Graphql
  class FieldSelection
    delegate :empty?, :blank?, :to_h, to: :selection
    delegate :size, to: :paths

    attr_reader :selection

    def initialize(selection = {})
      @selection = selection.to_h
    end

    def to_s
      serialize_field_selection(selection)
    end

    def paths
      selection.flat_map do |field, subselection|
        paths_in([field], subselection)
      end
    end

    private

    def paths_in(path, leaves)
      return [path] if leaves.nil?

      leaves.to_a.flat_map do |k, v|
        paths_in([k], v).map { |tail| path + tail }
      end
    end

    def serialize_field_selection(hash, level = 0)
      indent = ' ' * level

      hash.map do |field, subselection|
        if subselection.nil?
          "#{indent}#{field}"
        else
          subfields = serialize_field_selection(subselection, level + 1)
          "#{indent}#{field} {\n#{subfields}\n#{indent}}"
        end
      end.join("\n")
    end

    NO_SKIP = ->(_name, _field) { false }

    def self.select_fields(type, skip = NO_SKIP, max_depth = 3)
      return new if max_depth <= 0 || !type.kind.fields?

      new(type.fields.flat_map do |name, field|
        next [] if skip[name, field]

        inspected = ::Graphql::FieldInspection.new(field)
        singular_field_type = inspected.type

        if inspected.nested_fields?
          subselection = select_fields(singular_field_type, skip, max_depth - 1)
          next [] if subselection.empty?

          [[name, subselection.to_h]]
        else
          [[name, nil]]
        end
      end)
    end
  end
end
