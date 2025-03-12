# frozen_string_literal: true
require "spec_helper"

describe "Logger" do
  describe "Schema.default_logger" do
    if defined?(Rails)
      it "When Rails is present, returns the Rails logger" do
        prev_logger = Rails.logger # might be `nil`
        Rails.logger = Object.new
        assert_equal Rails.logger, GraphQL::Schema.default_logger
      ensure
        Rails.logger = prev_logger
      end

      it "When Rails is present but the logger is nil, it returns a new logger" do
        prev_logger = Rails.logger
        Rails.logger = nil
        refute_equal Rails.logger, GraphQL::Schema.default_logger
        assert_instance_of Logger, GraphQL::Schema.default_logger
      ensure
        Rails.logger = prev_logger
      end

    else
      it "Without Rails, returns a new logger" do
        assert_instance_of Logger, GraphQL::Schema.default_logger
      end

      it "Works when Rails doesn't have a logger" do
        rails_mod = Module.new
        Object.const_set(:Rails, rails_mod)
        assert_equal rails_mod, Rails
        assert_instance_of Logger, GraphQL::Schema.default_logger

        rails_mod.define_singleton_method(:logger) { false }
        assert Rails.respond_to?(:logger)
        assert_equal false, Rails.logger
        assert_instance_of Logger, GraphQL::Schema.default_logger
      ensure
        Object.send :remove_const, :Rails
      end
    end

    it "can be overridden" do
      new_logger = Logger.new($stdout)
      schema = Class.new(GraphQL::Schema) do
        default_logger(new_logger)
      end
      assert_equal new_logger, schema.default_logger
    end

    it "can be set to a null logger with nil" do
      schema = Class.new(GraphQL::Schema)
      schema.default_logger(nil)
      nil_logger = schema.default_logger
      std_out, std_err = capture_io do
        nil_logger.error("Blah")
        nil_logger.warn("Something")
        nil_logger.error("Hi")
      end
      assert_equal "", std_out
      assert_equal "", std_err
    end
  end

  describe "during execution" do
    module LoggerTest
      class DefaultLoggerSchema < GraphQL::Schema
        module Node
          include GraphQL::Schema::Interface
          field :id, ID
        end

        class Query < GraphQL::Schema::Object
          field :node, Node do
            argument :id, ID
          end

          def node(id:)
          end

          field :something_else, String
        end
        query(Query)
      end

      class CustomLoggerSchema < DefaultLoggerSchema
        LOG_STRING = StringIO.new
        LOGGER = Logger.new(LOG_STRING)
        LOGGER.level = :debug
        default_logger(LOGGER)
      end
    end

    before do
      LoggerTest::CustomLoggerSchema::LOG_STRING.truncate(0)
    end

    it "logs about hidden interfaces with no implementations" do
      res = LoggerTest::CustomLoggerSchema.execute("{ node(id: \"5\") { id } }", context: { skip_visibility_migration_error: true })
      if GraphQL::Schema.use_visibility_profile?
        assert_nil res["data"]["node"], "Schema::Visibility::Profile doesn't warn in this case -- it doesn't check possible types because it doesn't have to"
      else
        assert_equal ["Field 'node' doesn't exist on type 'Query'"], res["errors"].map { |err| err["message"] }
        assert_includes LoggerTest::CustomLoggerSchema::LOG_STRING.string, "Interface `Node` hidden because it has no visible implementers"
      end
    end

    it "doesn't print messages by default" do
      res = nil
      stdout, stderr = capture_io do
        res = LoggerTest::DefaultLoggerSchema.execute("{ node(id: \"5\") { id } }", context: { skip_visibility_migration_error: true })
      end

      if GraphQL::Schema.use_visibility_profile?
        assert_nil res["data"]["node"], "Schema::Visibility::Profile doesn't warn in this case -- it doesn't check possible types because it doesn't have to"
      else
        assert_equal ["Field 'node' doesn't exist on type 'Query'"], res["errors"].map { |err| err["message"] }
      end
      assert_equal "", stdout
      assert_equal "", stderr
    end
  end
end
