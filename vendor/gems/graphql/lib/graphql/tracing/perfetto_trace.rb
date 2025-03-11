# frozen_string_literal: true
module GraphQL
  module Tracing
    # This produces a trace file for inspecting in the [Perfetto Trace Viewer](https://ui.perfetto.dev).
    #
    # To get the file, call {#write} on the trace.
    #
    # Use "trace modes" to configure this to run on command or on a sample of traffic.
    #
    # @example Writing trace output
    #
    #   result = MySchema.execute(...)
    #   result.query.trace.write(file: "tmp/trace.dump")
    #
    # @example Running this instrumenter when `trace: true` is present in the request
    #
    #   class MySchema < GraphQL::Schema
    #     # Only run this tracer when `context[:trace_mode]` is `:trace`
    #     trace_with GraphQL::Tracing::Perfetto, mode: :trace
    #   end
    #
    #   # In graphql_controller.rb:
    #
    #   context[:trace_mode] = params[:trace] ? :trace : nil
    #   result = MySchema.execute(query_str, context: context, variables: variables, ...)
    #   if context[:trace_mode] == :trace
    #     result.trace.write(file: ...)
    #   end
    #
    module PerfettoTrace
      # TODOs:
      # - Make debug annotations visible on both parts when dataloader is involved

      PROTOBUF_AVAILABLE = begin
        require "google/protobuf"
        true
      rescue LoadError
        false
      end

      if PROTOBUF_AVAILABLE
        require "graphql/tracing/perfetto_trace/trace_pb"
      end

      def self.included(_trace_class)
        if !PROTOBUF_AVAILABLE
          raise "#{self} can't be used because the `google-protobuf` gem wasn't available. Add it to your project, then try again."
        end
      end

      DATALOADER_CATEGORY_IIDS = [5]
      FIELD_EXECUTE_CATEGORY_IIDS = [6]
      ACTIVE_SUPPORT_NOTIFICATIONS_CATEGORY_IIDS = [7]
      AUTHORIZED_CATEGORY_IIDS = [8]
      RESOLVE_TYPE_CATEGORY_IIDS = [9]

      DA_OBJECT_IID = 10
      DA_RESULT_IID = 11
      DA_ARGUMENTS_IID = 12
      DA_FETCH_KEYS_IID = 13
      DA_STR_VAL_NIL_IID = 14

      # @param active_support_notifications_pattern [String, RegExp, false] A filter for `ActiveSupport::Notifications`, if it's present. Or `false` to skip subscribing.
      def initialize(active_support_notifications_pattern: nil, save_profile: false, **_rest)
        super
        @save_profile = save_profile
        Fiber[:graphql_flow_stack] = nil
        @sequence_id = object_id
        @pid = Process.pid
        @flow_ids = Hash.new { |h, source_inst| h[source_inst] = [] }.compare_by_identity
        @new_interned_event_names = {}
        @interned_event_name_iids = Hash.new { |h, k|
          new_id = 100 + h.size
          @new_interned_event_names[k] = new_id
          h[k] = new_id
        }

        @source_name_iids = Hash.new do |h, source_class|
          h[source_class] = @interned_event_name_iids[source_class.name]
        end.compare_by_identity

        @auth_name_iids = Hash.new do |h, graphql_type|
          h[graphql_type] = @interned_event_name_iids["Authorize: #{graphql_type.graphql_name}"]
        end.compare_by_identity

        @resolve_type_name_iids = Hash.new do |h, graphql_type|
          h[graphql_type] = @interned_event_name_iids["Resolve Type: #{graphql_type.graphql_name}"]
        end.compare_by_identity

        @new_interned_da_names = {}
        @interned_da_name_ids = Hash.new { |h, k|
          next_id = 100 + h.size
          @new_interned_da_names[k] = next_id
          h[k] = next_id
        }

        @new_interned_da_string_values = {}
        @interned_da_string_values = Hash.new do |h, k|
          new_id = 100 + h.size
          @new_interned_da_string_values[k] = new_id
          h[k] = new_id
        end

        @class_name_iids = Hash.new do |h, k|
          h[k] = @interned_da_string_values[k.name]
        end.compare_by_identity

        @starting_objects = GC.stat(:total_allocated_objects)
        @objects_counter_id = :objects_counter.object_id
        @fibers_counter_id = :fibers_counter.object_id
        @fields_counter_id = :fields_counter.object_id
        @begin_validate = nil
        @begin_time = nil
        @packets = []
        @packets << TracePacket.new(
          track_descriptor: TrackDescriptor.new(
            uuid: tid,
            name: "Main Thread",
            child_ordering: TrackDescriptor::ChildTracksOrdering::CHRONOLOGICAL,
          ),
          first_packet_on_sequence: true,
          previous_packet_dropped: true,
          trusted_packet_sequence_id: @sequence_id,
          sequence_flags: 3,
        )
        @packets << TracePacket.new(
          interned_data: InternedData.new(
            event_categories: [
              EventCategory.new(name: "Dataloader", iid: DATALOADER_CATEGORY_IIDS.first),
              EventCategory.new(name: "Field Execution", iid: FIELD_EXECUTE_CATEGORY_IIDS.first),
              EventCategory.new(name: "ActiveSupport::Notifications", iid: ACTIVE_SUPPORT_NOTIFICATIONS_CATEGORY_IIDS.first),
              EventCategory.new(name: "Authorized", iid: AUTHORIZED_CATEGORY_IIDS.first),
              EventCategory.new(name: "Resolve Type", iid: RESOLVE_TYPE_CATEGORY_IIDS.first),
            ],
            debug_annotation_names: [
              DebugAnnotationName.new(name: "object", iid: DA_OBJECT_IID),
              DebugAnnotationName.new(name: "arguments", iid: DA_ARGUMENTS_IID),
              DebugAnnotationName.new(name: "result", iid: DA_RESULT_IID),
              DebugAnnotationName.new(name: "fetch keys", iid: DA_FETCH_KEYS_IID),
            ],
            debug_annotation_string_values: [
              InternedString.new(str: "(nil)", iid: DA_STR_VAL_NIL_IID),
            ],
          ),
          trusted_packet_sequence_id: @sequence_id,
          sequence_flags: 2,
        )
        @main_fiber_id = fid
        @packets << track_descriptor_packet(tid, fid, "Main Fiber")
        @packets << track_descriptor_packet(tid, @objects_counter_id, "Allocated Objects", counter: {})
        @packets << trace_packet(
          type: TrackEvent::Type::TYPE_COUNTER,
          track_uuid: @objects_counter_id,
          counter_value: count_allocations,
        )
        @packets << track_descriptor_packet(tid, @fibers_counter_id, "Active Fibers", counter: {})
        @fibers_count = 0
        @packets << trace_packet(
          type: TrackEvent::Type::TYPE_COUNTER,
          track_uuid: @fibers_counter_id,
          counter_value: count_fibers(0),
        )

        @packets << track_descriptor_packet(tid, @fields_counter_id, "Resolved Fields", counter: {})
        @fields_count = -1
        @packets << trace_packet(
          type: TrackEvent::Type::TYPE_COUNTER,
          track_uuid: @fields_counter_id,
          counter_value: count_fields,
        )

        if defined?(ActiveSupport::Notifications) && active_support_notifications_pattern != false
          subscribe_to_active_support_notifications(active_support_notifications_pattern)
        end
      end

      def begin_execute_multiplex(m)
        @operation_name = m.queries.map { |q| q.selected_operation_name || "anonymous" }.join(",")
        @begin_time = Time.now
        @packets << trace_packet(
          type: TrackEvent::Type::TYPE_SLICE_BEGIN,
          track_uuid: fid,
          name: "Multiplex",
          debug_annotations: [
            payload_to_debug("query_string", m.queries.map(&:sanitized_query_string).join("\n\n"))
          ]
        )
        super
      end

      def end_execute_multiplex(m)
        @packets << trace_packet(
          type: TrackEvent::Type::TYPE_SLICE_END,
          track_uuid: fid,
        )
        unsubscribe_from_active_support_notifications
        if @save_profile
          begin_ts = (@begin_time.to_f * 1000).round
          end_ts = (Time.now.to_f * 1000).round
          duration_ms = end_ts - begin_ts
          m.schema.detailed_trace.save_trace(@operation_name, duration_ms, begin_ts, Trace.encode(Trace.new(packet: @packets)))
        end
        super
      end

      def begin_execute_field(field, object, arguments, query)
        packet = trace_packet(
          type: TrackEvent::Type::TYPE_SLICE_BEGIN,
          track_uuid: fid,
          name: query.context.current_path.join("."),
          category_iids: FIELD_EXECUTE_CATEGORY_IIDS,
          extra_counter_track_uuids: [@objects_counter_id],
          extra_counter_values: [count_allocations],
        )
        @packets << packet
        fiber_flow_stack << packet
        super
      end

      def end_execute_field(field, object, arguments, query, app_result)
        start_field = fiber_flow_stack.pop
        start_field.track_event = dup_with(start_field.track_event, {
          debug_annotations: [
            payload_to_debug(nil, object.object, iid: DA_OBJECT_IID, intern_value: true),
            payload_to_debug(nil, arguments, iid: DA_ARGUMENTS_IID),
            payload_to_debug(nil, app_result, iid: DA_RESULT_IID, intern_value: true)
          ]
        })

        @packets << trace_packet(
          type: TrackEvent::Type::TYPE_SLICE_END,
          track_uuid: fid,
          extra_counter_track_uuids: [@objects_counter_id, @fields_counter_id],
          extra_counter_values: [count_allocations, count_fields],
        )
        super
      end

      def begin_analyze_multiplex(m, analyzers)
        @packets << trace_packet(
          type: TrackEvent::Type::TYPE_SLICE_BEGIN,
          track_uuid: fid,
          extra_counter_track_uuids: [@objects_counter_id],
          extra_counter_values: [count_allocations],
          name: "Analysis",
          debug_annotations: [
            payload_to_debug("analyzers_count", analyzers.size),
            payload_to_debug("analyzers", analyzers),
          ]
        )
        super
      end

      def end_analyze_multiplex(m, analyzers)
        @packets << trace_packet(
          type: TrackEvent::Type::TYPE_SLICE_END,
          track_uuid: fid,
          extra_counter_track_uuids: [@objects_counter_id],
          extra_counter_values: [count_allocations],
        )
        super
      end

      def begin_parse(str)
        @packets << trace_packet(
          type: TrackEvent::Type::TYPE_SLICE_BEGIN,
          track_uuid: fid,
          extra_counter_track_uuids: [@objects_counter_id],
          extra_counter_values: [count_allocations],
          name: "Parse"
        )
        super
      end

      def end_parse(str)
        @packets << trace_packet(
          type: TrackEvent::Type::TYPE_SLICE_END,
          track_uuid: fid,
          extra_counter_track_uuids: [@objects_counter_id],
          extra_counter_values: [count_allocations],
        )
        super
      end

      def begin_validate(query, validate)
        @packets << @begin_validate = trace_packet(
          type: TrackEvent::Type::TYPE_SLICE_BEGIN,
          track_uuid: fid,
          extra_counter_track_uuids: [@objects_counter_id],
          extra_counter_values: [count_allocations],
          name: "Validate",
          debug_annotations: [
            payload_to_debug("validate?", validate),
          ]
        )
        super
      end

      def end_validate(query, validate, validation_errors)
        @packets << trace_packet(
          type: TrackEvent::Type::TYPE_SLICE_END,
          track_uuid: fid,
          extra_counter_track_uuids: [@objects_counter_id],
          extra_counter_values: [count_allocations],
        )
        @begin_validate.track_event = dup_with(
          @begin_validate.track_event,
          {
            debug_annotations: [
              @begin_validate.track_event.debug_annotations.first,
              payload_to_debug("valid?", validation_errors.empty?)
            ]
          }
        )
        super
      end

      def dataloader_spawn_execution_fiber(jobs)
        @packets << trace_packet(
          type: TrackEvent::Type::TYPE_INSTANT,
          track_uuid: fid,
          name: "Create Execution Fiber",
          category_iids: DATALOADER_CATEGORY_IIDS,
          extra_counter_track_uuids: [@fibers_counter_id, @objects_counter_id],
          extra_counter_values: [count_fibers(1), count_allocations]
        )
        @packets << track_descriptor_packet(@did, fid, "Exec Fiber ##{fid}")
        super
      end

      def dataloader_spawn_source_fiber(pending_sources)
        @packets << trace_packet(
          type: TrackEvent::Type::TYPE_INSTANT,
          track_uuid: fid,
          name: "Create Source Fiber",
          category_iids: DATALOADER_CATEGORY_IIDS,
          extra_counter_track_uuids: [@fibers_counter_id, @objects_counter_id],
          extra_counter_values: [count_fibers(1), count_allocations]
        )
        @packets << track_descriptor_packet(@did, fid, "Source Fiber ##{fid}")
        super
      end

      def dataloader_fiber_yield(source)
        ls = fiber_flow_stack.last
        if (flow_id = ls.track_event.flow_ids.first)
          # got it
        else
          flow_id = ls.track_event.name.object_id
          ls.track_event = dup_with(ls.track_event, {flow_ids: [flow_id] }, delete_counters: true)
        end
        @flow_ids[source] << flow_id
        @packets << trace_packet(
          type: TrackEvent::Type::TYPE_SLICE_END,
          track_uuid: fid,
        )
        @packets << trace_packet(
          type: TrackEvent::Type::TYPE_INSTANT,
          track_uuid: fid,
          name: "Fiber Yield",
          category_iids: DATALOADER_CATEGORY_IIDS,
        )
        super
      end

      def dataloader_fiber_resume(source)
        @packets << trace_packet(
          type: TrackEvent::Type::TYPE_INSTANT,
          track_uuid: fid,
          name: "Fiber Resume",
          category_iids: DATALOADER_CATEGORY_IIDS,
        )

        ls = fiber_flow_stack.pop
        @packets << packet = TracePacket.new(
          timestamp: ts,
          track_event: dup_with(ls.track_event, { type: TrackEvent::Type::TYPE_SLICE_BEGIN }),
          trusted_packet_sequence_id: @sequence_id,
        )
        fiber_flow_stack << packet

        super
      end

      def dataloader_fiber_exit
        @packets << trace_packet(
          type: TrackEvent::Type::TYPE_INSTANT,
          track_uuid: fid,
          name: "Fiber Exit",
          category_iids: DATALOADER_CATEGORY_IIDS,
          extra_counter_track_uuids: [@fibers_counter_id],
          extra_counter_values: [count_fibers(-1)],
        )
        super
      end

      def begin_dataloader(dl)
        @packets << trace_packet(
          type: TrackEvent::Type::TYPE_COUNTER,
          track_uuid: @fibers_counter_id,
          counter_value: count_fibers(1),
        )
        @did = fid
        @packets << track_descriptor_packet(@main_fiber_id, @did, "Dataloader Fiber ##{@did}")
        super
      end

      def end_dataloader(dl)
        @packets << trace_packet(
          type: TrackEvent::Type::TYPE_COUNTER,
          track_uuid: @fibers_counter_id,
          counter_value: count_fibers(-1),
        )
        super
      end

      def begin_dataloader_source(source)
        fds = @flow_ids[source]
        fds_copy = fds.dup
        fds.clear
        packet = trace_packet(
          type: TrackEvent::Type::TYPE_SLICE_BEGIN,
          track_uuid: fid,
          name_iid: @source_name_iids[source.class],
          category_iids: DATALOADER_CATEGORY_IIDS,
          flow_ids: fds_copy,
          extra_counter_track_uuids: [@objects_counter_id],
          extra_counter_values: [count_allocations],
          debug_annotations: [
            payload_to_debug(nil, source.pending.values, iid: DA_FETCH_KEYS_IID, intern_value: true),
            *(source.instance_variables - [:@pending, :@fetching, :@results, :@dataloader]).map { |iv|
              payload_to_debug(iv.to_s, source.instance_variable_get(iv), intern_value: true)
            }
          ]
        )
        @packets << packet
        fiber_flow_stack << packet
        super
      end

      def end_dataloader_source(source)
        @packets << trace_packet(
          type: TrackEvent::Type::TYPE_SLICE_END,
          track_uuid: fid,
          extra_counter_track_uuids: [@objects_counter_id],
          extra_counter_values: [count_allocations],
        )
        fiber_flow_stack.pop
        super
      end

      def begin_authorized(type, obj, ctx)
        packet = trace_packet(
          type: TrackEvent::Type::TYPE_SLICE_BEGIN,
          track_uuid: fid,
          category_iids: AUTHORIZED_CATEGORY_IIDS,
          extra_counter_track_uuids: [@objects_counter_id],
          extra_counter_values: [count_allocations],
          name_iid: @auth_name_iids[type],
        )
        @packets << packet
        fiber_flow_stack << packet
        super
      end

      def end_authorized(type, obj, ctx, is_authorized)
        @packets << trace_packet(
          type: TrackEvent::Type::TYPE_SLICE_END,
          track_uuid: fid,
          extra_counter_track_uuids: [@objects_counter_id],
          extra_counter_values: [count_allocations],
        )
        beg_auth = fiber_flow_stack.pop
        beg_auth.track_event = dup_with(beg_auth.track_event, { debug_annotations: [payload_to_debug("authorized?", is_authorized)] })
        super
      end

      def begin_resolve_type(type, value, context)
        packet = trace_packet(
          type: TrackEvent::Type::TYPE_SLICE_BEGIN,
          track_uuid: fid,
          category_iids: RESOLVE_TYPE_CATEGORY_IIDS,
          extra_counter_track_uuids: [@objects_counter_id],
          extra_counter_values: [count_allocations],
          name_iid: @resolve_type_name_iids[type],
        )
        @packets << packet
        fiber_flow_stack << packet
        super
      end

      def end_resolve_type(type, value, context, resolved_type)
        @packets << trace_packet(
          type: TrackEvent::Type::TYPE_SLICE_END,
          track_uuid: fid,
          extra_counter_track_uuids: [@objects_counter_id],
          extra_counter_values: [count_allocations],
        )
        rt_begin = fiber_flow_stack.pop
        rt_begin.track_event = dup_with(rt_begin.track_event, { debug_annotations: [payload_to_debug("resolved_type", resolved_type, intern_value: true)] })
        super
      end

      # Dump protobuf output in the specified file.
      # @param file [String] path to a file in a directory that already exists
      # @param debug_json [Boolean] True to print JSON instead of binary
      # @return [nil, String, Hash] If `file` was given, `nil`. If `file` was `nil`, a Hash if `debug_json: true`, else binary data.
      def write(file:, debug_json: false)
        trace = Trace.new(
          packet: @packets,
        )
        data = if debug_json
          small_json = Trace.encode_json(trace)
          JSON.pretty_generate(JSON.parse(small_json))
        else
          Trace.encode(trace)
        end

        if file
          File.write(file, data, mode: 'wb')
          nil
        else
          data
        end
      end

      private

      def ts
        Process.clock_gettime(Process::CLOCK_MONOTONIC, :nanosecond)
      end

      def tid
        Thread.current.object_id
      end

      def fid
        Fiber.current.object_id
      end

      def debug_annotation(iid, value_key, value)
        if iid
          DebugAnnotation.new(name_iid: iid, value_key => value)
        else
          DebugAnnotation.new(value_key => value)
        end
      end

      def payload_to_debug(k, v, iid: nil, intern_value: false)
        if iid.nil?
          iid = @interned_da_name_ids[k]
          k = nil
        end
        case v
        when String
          if intern_value
            v = @interned_da_string_values[v]
            debug_annotation(iid, :string_value_iid, v)
          else
            debug_annotation(iid, :string_value, v)
          end
        when Float
          debug_annotation(iid, :double_value, v)
        when Integer
          debug_annotation(iid, :int_value, v)
        when true, false
          debug_annotation(iid, :bool_value, v)
        when nil
          if iid
            DebugAnnotation.new(name_iid: iid, string_value_iid: DA_STR_VAL_NIL_IID)
          else
            DebugAnnotation.new(name: k, string_value_iid: DA_STR_VAL_NIL_IID)
          end
        when Module
          if intern_value
            val_iid = @class_name_iids[v]
            debug_annotation(iid, :string_value_iid, val_iid)
          else
            debug_annotation(iid, :string_value, v.name)
          end
        when Symbol
          debug_annotation(iid, :string_value, v.inspect)
        when Array
          debug_annotation(iid, :array_values, v.map { |v2| payload_to_debug(nil, v2, intern_value: intern_value) }.compact)
        when Hash
          debug_annotation(iid, :dict_entries, v.map { |k2, v2| payload_to_debug(k2, v2, intern_value: intern_value) }.compact)
        else
          debug_str = if defined?(ActiveRecord::Relation) && v.is_a?(ActiveRecord::Relation)
            "#{v.class}, .to_sql=#{v.to_sql.inspect}"
          else
            v.inspect
          end
          if intern_value
            str_iid = @interned_da_string_values[debug_str]
            debug_annotation(iid, :string_value_iid, str_iid)
          else
            debug_annotation(iid, :string_value, debug_str)
          end
        end
      end

      def count_allocations
        GC.stat(:total_allocated_objects) - @starting_objects
      end

      def count_fibers(diff)
        @fibers_count += diff
      end

      def count_fields
        @fields_count += 1
      end

      def dup_with(message, attrs, delete_counters: false)
        new_attrs = message.to_h
        if delete_counters
          new_attrs.delete(:extra_counter_track_uuids)
          new_attrs.delete(:extra_counter_values)
        end
        new_attrs.merge!(attrs)
        message.class.new(**new_attrs)
      end

      def fiber_flow_stack
        Fiber[:graphql_flow_stack] ||= []
      end

      def trace_packet(event_attrs)
        TracePacket.new(
          timestamp: ts,
          track_event: TrackEvent.new(event_attrs),
          trusted_packet_sequence_id: @sequence_id,
          sequence_flags: 2,
          interned_data: new_interned_data
        )
      end

      def new_interned_data
        if !@new_interned_da_names.empty?
          da_names = @new_interned_da_names.map { |(name, iid)| DebugAnnotationName.new(iid: iid, name: name) }
          @new_interned_da_names.clear
        end

        if !@new_interned_event_names.empty?
          ev_names = @new_interned_event_names.map { |(name, iid)| EventName.new(iid: iid, name: name) }
          @new_interned_event_names.clear
        end

        if !@new_interned_da_string_values.empty?
          str_vals = @new_interned_da_string_values.map { |name, iid| InternedString.new(iid: iid, str: name) }
          @new_interned_da_string_values.clear
        end

        if ev_names || da_names || str_vals
          InternedData.new(
            event_names: ev_names,
            debug_annotation_names: da_names,
            debug_annotation_string_values: str_vals,
          )
        else
          nil
        end
      end

      def track_descriptor_packet(parent_uuid, uuid, name, counter: nil)
        td = if counter
          TrackDescriptor.new(
            parent_uuid: parent_uuid,
            uuid: uuid,
            name: name,
            counter: counter
          )
        else
          TrackDescriptor.new(
            parent_uuid: parent_uuid,
            uuid: uuid,
            name: name,
            child_ordering: TrackDescriptor::ChildTracksOrdering::CHRONOLOGICAL,
          )
        end
        TracePacket.new(
          track_descriptor: td,
          trusted_packet_sequence_id: @sequence_id,
          sequence_flags: 2,
        )
      end

      def unsubscribe_from_active_support_notifications
        if defined?(@as_subscriber)
          ActiveSupport::Notifications.unsubscribe(@as_subscriber)
        end
      end

      def subscribe_to_active_support_notifications(pattern)
        @as_subscriber = ActiveSupport::Notifications.monotonic_subscribe(pattern) do |name, start, finish, id, payload|
          metadata = payload.map { |k, v| payload_to_debug(k, v, intern_value: true) }
          metadata.compact!
          te = if metadata.empty?
            TrackEvent.new(
              type: TrackEvent::Type::TYPE_SLICE_BEGIN,
              track_uuid: fid,
              category_iids: ACTIVE_SUPPORT_NOTIFICATIONS_CATEGORY_IIDS,
              name: name,
            )
          else
            TrackEvent.new(
              type: TrackEvent::Type::TYPE_SLICE_BEGIN,
              track_uuid: fid,
              name: name,
              category_iids: ACTIVE_SUPPORT_NOTIFICATIONS_CATEGORY_IIDS,
              debug_annotations: metadata,
            )
          end
          @packets << TracePacket.new(
            timestamp: (start * 1_000_000_000).to_i,
            track_event: te,
            trusted_packet_sequence_id: @sequence_id,
            sequence_flags: 2,
            interned_data: new_interned_data
          )
          @packets << TracePacket.new(
            timestamp: (finish * 1_000_000_000).to_i,
            track_event: TrackEvent.new(
              type: TrackEvent::Type::TYPE_SLICE_END,
              track_uuid: fid,
              name: name,
              extra_counter_track_uuids: [@objects_counter_id],
              extra_counter_values: [count_allocations]
            ),
            trusted_packet_sequence_id: @sequence_id,
            sequence_flags: 2,
          )
        end
      end
    end
  end
end
