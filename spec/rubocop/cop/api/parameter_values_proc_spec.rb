# frozen_string_literal: true

require "rubocop_spec_helper"
require_relative "../../../../rubocop/cop/api/parameter_values_proc"

RSpec.describe RuboCop::Cop::API::ParameterValuesProc, :config, feature_category: :api do
  let(:msg) do
    "Do not use a Proc for `values:` in API parameters. " \
      "Proc-based values cannot be represented as a static enum in the OpenAPI spec. " \
      "Use a statically resolvable value instead (e.g. an array, range, or constant). " \
  end

  context "when values: contains a Proc" do
    it "registers an offense for a lambda" do
      expect_offense(<<~RUBY, msg: msg)
        params do
          requires :storage, type: String, values: -> { Gitlab.config.repositories.storages.keys }
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ %{msg}
        end
      RUBY
    end

    it "registers an offense for a proc block" do
      expect_offense(<<~RUBY, msg: msg)
        params do
          requires :status, type: String, values: proc { Status.names }
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ %{msg}
        end
      RUBY
    end

    it "registers an offense for Proc.new" do
      expect_offense(<<~RUBY, msg: msg)
        params do
          requires :status, type: String, values: Proc.new { Status.names }
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ %{msg}
        end
      RUBY
    end

    it "registers an offense for to_proc" do
      expect_offense(<<~RUBY, msg: msg)
        params do
          requires :status, type: Integer, values: (1..120).method(:cover?).to_proc
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ %{msg}
        end
      RUBY
    end

    it "registers an offense for a hash-wrapped proc" do
      expect_offense(<<~RUBY, msg: msg)
        params do
          requires :storage, type: String, values: { value: -> { Gitlab.config.repositories.storages.keys } }
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ %{msg}
        end
      RUBY
    end

    it "registers an offense for a variable assigned a lambda" do
      expect_offense(<<~RUBY, msg: msg)
        allowed = -> { Gitlab.config.repositories.storages.keys }
        params do
          requires :storage, type: String, values: allowed
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ %{msg}
        end
      RUBY
    end

    it "registers an offense for multiline params" do
      expect_offense(<<~RUBY, msg: msg)
        params do
          requires :storage,
          ^^^^^^^^^^^^^^^^^^ %{msg}
            type: String,
            values: -> { Gitlab.config.repositories.storages.keys },
            desc: 'The storage'
        end
      RUBY
    end

    it "registers an offense for optional params" do
      expect_offense(<<~RUBY, msg: msg)
        params do
          optional :status, type: String, values: -> { Status.names }
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ %{msg}
        end
      RUBY
    end
  end

  context "when values: does not contain a Proc" do
    it "does not register an offense for a static array" do
      expect_no_offenses(<<~RUBY)
        params do
          requires :status, type: String, values: %w[active inactive]
        end
      RUBY
    end

    it "does not register an offense for an array literal" do
      expect_no_offenses(<<~RUBY)
        params do
          requires :status, type: String, values: ['active', 'inactive']
        end
      RUBY
    end

    it "does not register an offense for a constant" do
      expect_no_offenses(<<~RUBY)
        params do
          requires :status, type: String, values: ALLOWED_STATUSES
        end
      RUBY
    end

    it "does not register an offense when values: is absent" do
      expect_no_offenses(<<~RUBY)
        params do
          requires :id, type: Integer
          optional :search, type: String
        end
      RUBY
    end

    it "does not register an offense for a proc in a non-values option" do
      expect_no_offenses(<<~RUBY)
        params do
          requires :name, type: String, coerce_with: ->(val) { val.strip }
        end
      RUBY
    end
  end
end
