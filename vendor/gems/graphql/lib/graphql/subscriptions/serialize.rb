# frozen_string_literal: true
require "set"
module GraphQL
  class Subscriptions
    # Serialization helpers for passing subscription data around.
    # @api private
    module Serialize
      GLOBALID_KEY = "__gid__"
      SYMBOL_KEY = "__sym__"
      SYMBOL_KEYS_KEY = "__sym_keys__"
      TIMESTAMP_KEY = "__timestamp__"
      TIMESTAMP_FORMAT = "%Y-%m-%d %H:%M:%S.%N%z" # eg '2020-01-01 23:59:59.123456789+05:00'
      OPEN_STRUCT_KEY = "__ostruct__"

      module_function

      # @param str [String] A serialized object from {.dump}
      # @return [Object] An object equivalent to the one passed to {.dump}
      def load(str)
        parsed_obj = JSON.parse(str)
        load_value(parsed_obj)
      end

      # @param obj [Object] Some subscription-related data to dump
      # @return [String] The stringified object
      def dump(obj)
        JSON.generate(dump_value(obj), quirks_mode: true)
      end

      # This is for turning objects into subscription scopes.
      # It's a one-way transformation, can't reload this :'(
      # @param obj [Object]
      # @return [String]
      def dump_recursive(obj)
        case
        when obj.is_a?(Array)
          obj.map { |i| dump_recursive(i) }.join(':')
        when obj.is_a?(Hash)
          obj.map { |k, v| "#{dump_recursive(k)}:#{dump_recursive(v)}" }.join(":")
        when obj.is_a?(GraphQL::Schema::InputObject)
          dump_recursive(obj.to_h)
        when obj.respond_to?(:to_gid_param)
          obj.to_gid_param
        when obj.respond_to?(:to_param)
          obj.to_param
        else
          obj.to_s
        end
      end

      class << self
        private

        # @param value [Object] A parsed JSON object
        # @return [Object] An object that load Global::Identification recursive
        def load_value(value)
          if value.is_a?(Array)
            is_gids = (v1 = value[0]).is_a?(Hash) && v1.size == 1 && v1[GLOBALID_KEY]
            if is_gids
              # Assume it's an array of global IDs
              ids = value.map { |v| v[GLOBALID_KEY] }
              GlobalID::Locator.locate_many(ids)
            else
              value.map { |item| load_value(item) }
            end
          elsif value.is_a?(Hash)
            if value.size == 1
              case value.keys.first # there's only 1 key
              when GLOBALID_KEY
                GlobalID::Locator.locate(value[GLOBALID_KEY])
              when SYMBOL_KEY
                value[SYMBOL_KEY].to_sym
              when TIMESTAMP_KEY
                timestamp_class_name, *timestamp_args = value[TIMESTAMP_KEY]
                timestamp_class = Object.const_get(timestamp_class_name)
                if defined?(ActiveSupport::TimeWithZone) && timestamp_class <= ActiveSupport::TimeWithZone
                  zone_name, timestamp_s = timestamp_args
                  zone = ActiveSupport::TimeZone[zone_name]
                  raise "Zone #{zone_name} not found, unable to deserialize" unless zone
                  zone.strptime(timestamp_s, TIMESTAMP_FORMAT)
                else
                  timestamp_s = timestamp_args.first
                  timestamp_class.strptime(timestamp_s, TIMESTAMP_FORMAT)
                end
              when OPEN_STRUCT_KEY
                ostruct_values = load_value(value[OPEN_STRUCT_KEY])
                OpenStruct.new(ostruct_values)
              else
                key = value.keys.first
                { key => load_value(value[key]) }
              end
            else
              loaded_h = {}
              sym_keys = value.fetch(SYMBOL_KEYS_KEY, [])
              value.each do |k, v|
                if k == SYMBOL_KEYS_KEY
                  next
                end
                if sym_keys.include?(k)
                  k = k.to_sym
                end
                loaded_h[k] = load_value(v)
              end
              loaded_h
            end
          else
            value
          end
        end

        # @param obj [Object] Some subscription-related data to dump
        # @return [Object] The object that converted Global::Identification
        def dump_value(obj)
          if obj.is_a?(Array)
            obj.map{|item| dump_value(item)}
          elsif obj.is_a?(Hash)
            symbol_keys = nil
            dumped_h = {}
            obj.each do |k, v|
              dumped_h[k.to_s] = dump_value(v)
              if k.is_a?(Symbol)
                symbol_keys ||= Set.new
                symbol_keys << k.to_s
              end
            end
            if symbol_keys
              dumped_h[SYMBOL_KEYS_KEY] = symbol_keys.to_a
            end
            dumped_h
          elsif obj.is_a?(Symbol)
            { SYMBOL_KEY => obj.to_s }
          elsif obj.respond_to?(:to_gid_param)
            {GLOBALID_KEY => obj.to_gid_param}
          elsif defined?(ActiveSupport::TimeWithZone) && obj.is_a?(ActiveSupport::TimeWithZone) && obj.class.name != Time.name
            # This handles a case where Rails prior to 7 would
            # make the class ActiveSupport::TimeWithZone return "Time" for
            # its name. In Rails 7, it will now return "ActiveSupport::TimeWithZone",
            # which happens to be incompatible with expectations we have
            # with what a Time class supports ( notably, strptime in `load_value` ).
            #
            # This now passes along the name of the zone, such that a future deserialization
            # of this string will use the correct time zone from the ActiveSupport TimeZone
            # list to produce the time.
            #
            { TIMESTAMP_KEY => [obj.class.name, obj.time_zone.name, obj.strftime(TIMESTAMP_FORMAT)] }
          elsif obj.is_a?(Date) || obj.is_a?(Time)
            # DateTime extends Date; for TimeWithZone, call `.utc` first.
            { TIMESTAMP_KEY => [obj.class.name, obj.strftime(TIMESTAMP_FORMAT)] }
          elsif defined?(OpenStruct) && obj.is_a?(OpenStruct)
            { OPEN_STRUCT_KEY => dump_value(obj.to_h) }
          elsif defined?(ActiveRecord::Relation) && obj.is_a?(ActiveRecord::Relation)
            dump_value(obj.to_a)
          else
            obj
          end
        end
      end
    end
  end
end
