# frozen_string_literal: true
require "spec_helper"

describe "Trace modes for schemas" do
  module TraceModesTest
    class ParentSchema < GraphQL::Schema
      module GlobalTrace
        def execute_query(query:)
          query.context[:global_trace] = true
          super
        end
      end

      module SpecialTrace
        def execute_query(query:)
          query.context[:special_trace] = true
          super
        end
      end

      module OptionsTrace
        def initialize(configured_option:, **_rest)
          @configured_option = configured_option
          super
        end

        def execute_query(query:)
          query.context[:configured_option] = @configured_option
          super
        end
      end

      class Query < GraphQL::Schema::Object
        field :greeting, String, fallback_value: "Howdy!"
      end

      query(Query)

      trace_with GlobalTrace, global_arg: 1
      trace_with SpecialTrace, mode: :special
      trace_with OptionsTrace, mode: :options, configured_option: :was_configured
    end

    class ChildSchema < ParentSchema
      module ChildSpecialTrace
        def execute_query(query:)
          query.context[:child_special_trace] = true
          super
        end
      end

      trace_with(ChildSpecialTrace, mode: [:special, :extra_special])
    end

    class GrandchildSchema < ChildSchema
      module GrandchildDefaultTrace
        def execute_query(query:)
          query.context[:grandchild_default] = true
          super
        end
      end

      trace_with GrandchildDefaultTrace
    end
  end

  it "traces are inherited from default modes" do
    res = TraceModesTest::ParentSchema.execute("{ greeting }")
    assert res.context[:global_trace]
    refute res.context[:grandchild_default]

    res = TraceModesTest::ChildSchema.execute("{ greeting }")
    assert res.context[:global_trace]
    refute res.context[:grandchild_default]

    res = TraceModesTest::GrandchildSchema.execute("{ greeting }")
    assert res.context[:global_trace]
    assert res.context[:grandchild_default]
  end

  it "uses the default trace class and trace options for unknown modes" do
    assert_nil TraceModesTest::ParentSchema.trace_class_for(:who_knows_what2)
    constructed_trace_class = TraceModesTest::ParentSchema.trace_class_for(:who_knows_what2, build: true)
    assert_equal TraceModesTest::ParentSchema.trace_class_for(:default), constructed_trace_class.superclass

    assert_equal({global_arg: 1}, TraceModesTest::ParentSchema.trace_options_for(:who_know_what3))
  end

  it "uses the default trace mode when an unknown mode is given" do
    res = TraceModesTest::ParentSchema.execute("{ greeting }", context: { trace_mode: :who_knows_what })
    assert res.context[:global_trace]
  end

  it "inherits special modes" do
    res = TraceModesTest::ParentSchema.execute("{ greeting }", context: { trace_mode: :special })
    assert res.context[:global_trace]
    assert res.context[:special_trace]
    refute res.context[:child_special_trace]
    refute res.context[:grandchild_default]

    res = TraceModesTest::ChildSchema.execute("{ greeting }", context: { trace_mode: :special })
    assert res.context[:global_trace]
    assert res.context[:special_trace]
    assert res.context[:child_special_trace]
    refute res.context[:grandchild_default]

    # This doesn't inherit `:special` configs from ParentSchema:
    res = TraceModesTest::ChildSchema.execute("{ greeting }", context: { trace_mode: :extra_special })
    assert res.context[:global_trace]
    refute res.context[:special_trace]
    assert res.context[:child_special_trace]
    refute res.context[:grandchild_default]

    res = TraceModesTest::GrandchildSchema.execute("{ greeting }", context: { trace_mode: :special })
    assert res.context[:global_trace]
    assert res.context[:special_trace]
    assert res.context[:child_special_trace]
    assert res.context[:grandchild_default]
  end

  it "Only requires and passes arguments for the modes that require them" do
    res = TraceModesTest::ParentSchema.execute("{ greeting }", context: { trace_mode: :options })
    assert_equal :was_configured, res.context[:configured_option]
  end

  describe "inheriting from GraphQL::Schema" do
    it "gets CallLegacyTracers" do
      # Use a new base trace mode class to avoid polluting the base class
      # which already-initialized schemas have in their inheritance chain
      # (It causes `CallLegacyTracers` to end up in the chain twice otherwise)
      GraphQL::Schema.send(:remove_const, :DefaultTrace)
      GraphQL::Schema.own_trace_modes[:default] = GraphQL::Schema.build_trace_mode(:default)

      child_class = Class.new(GraphQL::Schema)

      # Initialize the trace class, make sure no legacy tracers are present at this point:
      refute_includes child_class.trace_class_for(:default).ancestors, GraphQL::Tracing::CallLegacyTracers
      tracer_class = Class.new

      # add a legacy tracer
      GraphQL::Schema.tracer(tracer_class, silence_deprecation_warning: true)
      # A newly created child class gets the right setup:
      new_child_class = Class.new(GraphQL::Schema)
      assert_includes new_child_class.trace_class_for(:default).ancestors, GraphQL::Tracing::CallLegacyTracers
      # But what about an already-created child class?
      assert_includes child_class.trace_class_for(:default).ancestors, GraphQL::Tracing::CallLegacyTracers

      # Reset GraphQL::Schema tracer state:
      GraphQL::Schema.send(:remove_const, :DefaultTrace)
      GraphQL::Schema.send(:own_tracers).delete(tracer_class)
      GraphQL::Schema.own_trace_modes[:default] = GraphQL::Schema.build_trace_mode(:default)
      refute_includes GraphQL::Schema.new_trace.class.ancestors, GraphQL::Tracing::CallLegacyTracers
    ensure
      # Since this modifies the base class, make sure it's undone for future test cases
      GraphQL::Schema.instance_variable_get(:@own_tracers).clear
      GraphQL::Schema.own_trace_modes.clear
      GraphQL::Schema.own_trace_modules.clear
      GraphQL::Schema.instance_variable_get(:@trace_options_for_mode).clear
    end
  end

  describe "inheriting from a custom default trace class" do
    class CustomBaseTraceParentSchema < GraphQL::Schema
      class CustomTrace < GraphQL::Tracing::Trace
      end

      trace_class CustomTrace
    end

    class CustomBaseTraceSubclassSchema < CustomBaseTraceParentSchema
      trace_with Module.new, mode: :special_with_base_class
    end

    class TraceWithWithOptionsSchema < GraphQL::Schema
      class CustomTrace < GraphQL::Tracing::Trace
      end

      module OptionsTrace
        def initialize(configured_option:, **_rest)
          @configured_option = configured_option
          super
        end
      end

      trace_class CustomTrace
      trace_with OptionsTrace, configured_option: :foo
    end


    it "uses the default trace class for default mode" do
      assert_equal CustomBaseTraceParentSchema::CustomTrace, CustomBaseTraceParentSchema.trace_class_for(:default)
      assert_equal CustomBaseTraceParentSchema::CustomTrace, CustomBaseTraceSubclassSchema.trace_class_for(:default).superclass

      assert_instance_of CustomBaseTraceParentSchema::CustomTrace, CustomBaseTraceParentSchema.new_trace
      assert_kind_of CustomBaseTraceParentSchema::CustomTrace, CustomBaseTraceSubclassSchema.new_trace
    end

    it "uses the default trace class for special modes" do
      assert_includes CustomBaseTraceSubclassSchema.trace_class_for(:special_with_base_class).ancestors, CustomBaseTraceParentSchema::CustomTrace
      assert_kind_of CustomBaseTraceParentSchema::CustomTrace, CustomBaseTraceSubclassSchema.new_trace(mode: :special_with_base_class)
    end

    it "custom options are retained when using `trace_with` when there is already default tracer configured with `trace_class`" do
      assert_equal({configured_option: :foo}, TraceWithWithOptionsSchema.trace_options_for(:default))
    end
  end

  describe "custom default trace mode" do
    class CustomDefaultSchema < TraceModesTest::ParentSchema
      class CustomDefaultTrace < GraphQL::Tracing::Trace
        def execute_query(query:)
          query.context[:custom_default_used] = true
          super
        end
      end

      trace_mode :custom_default, CustomDefaultTrace
      default_trace_mode :custom_default
    end

    class ChildCustomDefaultSchema < CustomDefaultSchema
    end

    it "inherits configuration" do
      assert_equal :default, TraceModesTest::ParentSchema.default_trace_mode
      assert_equal :custom_default, CustomDefaultSchema.default_trace_mode
      assert_equal :custom_default, ChildCustomDefaultSchema.default_trace_mode
    end

    it "uses the specified default when none is given" do
      res = CustomDefaultSchema.execute("{ greeting }")
      assert res.context[:custom_default_used]
      refute res.context[:global_trace]

      res2 = ChildCustomDefaultSchema.execute("{ greeting }")
      assert res2.context[:custom_default_used]
      refute res2.context[:global_trace]
    end
  end

  describe "custom mode options and default options" do
    class ModeOptionsSchema < GraphQL::Schema
      module SomePlugin
        def self.use(schema)
          schema.trace_with(Trace, arg1: 1)
        end

        module Trace
          def initialize(arg1:, **kwargs)
            super(**kwargs)
          end
        end
      end
      module BaseTracer
        def initialize(arg3:, **kwargs)
          super(**kwargs)
        end
      end

      module ExtraTracer
        def initialize(arg2:, **kwargs)
          super(**kwargs)
        end
      end

      use SomePlugin
      trace_with(ExtraTracer, mode: :extra, arg2: true)
      trace_with(BaseTracer, arg3: true)
    end

    it "merges default options into custom mode options" do
      assert_equal [:arg1, :arg3], ModeOptionsSchema.trace_options_for(:default).keys.sort
      assert_equal [:arg1, :arg2, :arg3], ModeOptionsSchema.trace_options_for(:extra).keys.sort

      assert ModeOptionsSchema.new_trace(mode: :default)
      assert ModeOptionsSchema.new_trace(mode: :extra)
    end
  end

  module SomeTraceMod
    def execute_query(query)
      super
    end
  end

  CustomTraceClass = Class.new(GraphQL::Tracing::Trace)

  class BaseSchemaWithCustomTraceClass < GraphQL::Schema
    use(GraphQL::Batch)
    trace_class(CustomTraceClass)
    trace_with(SomeTraceMod)
  end

  ChildSchema = Class.new(BaseSchemaWithCustomTraceClass)

  describe "custom trace class supports trace module inheritance" do
    it "inherits parent trace modules" do
      assert_equal [GraphQL::Batch::SetupMultiplex::Trace, SomeTraceMod], ChildSchema.trace_modules_for(:default)
      assert ChildSchema.new_trace.instance_variable_defined?(:@executor_class)
    end
  end

  describe "when GraphQL::Schema gets a new default trace" do
    module NewDefaultTrace
      module ParentClassTrace
        def execute_query(query:)
          query[:parent_trace_ran] = true
          super
        end
      end

      module ChildClassTrace
        def execute_query(query:)
          query[:child_trace_ran] = true
          super
        end
      end

      class ParentSchema < GraphQL::Schema
      end

      class ChildSchema < ParentSchema
        trace_with(ChildClassTrace)
      end

      ParentSchema.trace_with(ParentClassTrace)
    end

    it "still uses custom traces on subclasses" do
      dummy_query = {}
      finished = false
      NewDefaultTrace::ChildSchema.new_trace.execute_query(query: dummy_query) { finished = true }
      assert dummy_query[:child_trace_ran]
      assert dummy_query[:parent_trace_ran]
      assert finished
    end
  end
end
