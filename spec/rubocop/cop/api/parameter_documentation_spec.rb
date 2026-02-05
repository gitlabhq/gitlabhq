# frozen_string_literal: true

require "rubocop_spec_helper"
require_relative "../../../../rubocop/cop/api/parameter_documentation"

RSpec.describe RuboCop::Cop::API::ParameterDocumentation, :config, feature_category: :api do
  let(:msg_values) do
    "Parameter is constrained to a set of values determined at runtime. " \
      "Include a `documentation` field to inform about the allowed values as precisely as possible."
  end

  let(:msg_default) do
    "Parameter has a default value determined at runtime. " \
      "Include a `documentation` field to inform about the default as precisely as possible."
  end

  context "when params have a Proc in values:" do
    context "with documentation" do
      it "does not register an offense for lambda values" do
        expect_no_offenses(<<~RUBY)
          params do
            requires :status, type: String, values: -> { Status.names }, documentation: { example: 'active' }
            optional :limit, type: Integer, default: -> { Config.limit }, documentation: { example: 10 }
          end
        RUBY
      end

      it "does not register an offense for Proc values" do
        expect_no_offenses(<<~RUBY)
          params do
            requires :status, type: String, values: proc { Status.names }, documentation: { example: 'active' }
            optional :limit, type: Integer, default: proc { Config.limit }, documentation: { example: 10 }
          end
        RUBY
      end

      it "does not register an offense for multiline params" do
        expect_no_offenses(<<~RUBY)
          params do
            requires :status,
              type: String,
              values: -> { Status.names },
              documentation: { example: 'active' },
              desc: 'The status'
          end
        RUBY
      end
    end

    context "without documentation" do
      it "registers an offense for lambda values" do
        expect_offense(<<~RUBY, msg: msg_values)
          params do
            requires :status, type: String, values: -> { Status.names }
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ %{msg}
          end
        RUBY
      end

      it "registers an offense for Proc values" do
        expect_offense(<<~RUBY, msg: msg_values)
          params do
            requires :status, type: String, values: proc { Status.names }
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ %{msg}
          end
        RUBY
      end

      it "registers an offense for Proc.new values" do
        expect_offense(<<~RUBY, msg: msg_values)
          params do
            requires :status, type: String, values: Proc.new { Status.names }
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ %{msg}
          end
        RUBY
      end

      it "registers an offense for to_proc values" do
        expect_offense(<<~RUBY, msg: msg_values)
          params do
            requires :status, type: Integer, values: (1..120).method(:cover?).to_proc
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ %{msg}
          end
        RUBY
      end

      it "registers an offense for multiline params" do
        expect_offense(<<~RUBY, msg: msg_values)
          params do
            requires :status,
            ^^^^^^^^^^^^^^^^^ %{msg}
              type: String,
              values: -> { Status.names },
              desc: 'The status'
          end
        RUBY
      end
    end
  end

  context "when params have a Proc in default:" do
    context "with documentation" do
      it "does not register an offense for lambda values" do
        expect_no_offenses(<<~RUBY)
          params do
            optional :limit, type: Integer, default: -> { Config.limit }, documentation: { example: 10 }
          end
        RUBY
      end

      it "does not register an offense for Proc values" do
        expect_no_offenses(<<~RUBY)
          params do
            optional :limit, type: Integer, default: proc { Config.limit }, documentation: { example: 10 }
          end
        RUBY
      end

      it "does not register an offense for multiline params" do
        expect_no_offenses(<<~RUBY)
          params do
            optional :limit,
              type: Integer,
              default: proc { Config.limit },
              documentation: { example: 10 },
              desc: 'The limit'
          end
        RUBY
      end
    end

    context "without documentation" do
      it "registers an offense for lambda values" do
        expect_offense(<<~RUBY, msg: msg_default)
          params do
            optional :limit, type: Integer, default: -> { Config.limit }
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ %{msg}
          end
        RUBY
      end

      it "registers an offense for Proc values" do
        expect_offense(<<~RUBY, msg: msg_default)
          params do
            optional :limit, type: Integer, default: proc { Config.limit }
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ %{msg}
          end
        RUBY
      end

      it "registers an offense for Proc.new values" do
        expect_offense(<<~RUBY, msg: msg_default)
          params do
            optional :limit, type: Integer, default: Proc.new { Config.limit }
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ %{msg}
          end
        RUBY
      end

      it "registers an offense for to_proc values" do
        expect_offense(<<~RUBY, msg: msg_default)
          params do
            optional :limit, type: Integer, default: (1..120).method(:first).to_proc
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ %{msg}
          end
        RUBY
      end

      it "registers an offense for multiline params" do
        expect_offense(<<~RUBY, msg: msg_default)
          params do
            optional :limit,
            ^^^^^^^^^^^^^^^^ %{msg}
              type: Integer,
              default: proc { Config.limit },
              desc: 'The limit'
          end
        RUBY
      end
    end
  end

  context "when params do not have a Proc in values: or default:" do
    it "does not register an offense without documentation" do
      expect_no_offenses(<<~RUBY)
        params do
          requires :id, types: [String, Integer]
          optional :search, type: String
        end
      RUBY
    end

    it "does not register an offense for static values" do
      expect_no_offenses(<<~RUBY)
        params do
          requires :status, type: String, values: %w[active inactive]
          optional :limit, type: Integer, default: 10
        end
      RUBY
    end

    it "does not register an offense for hash type params" do
      expect_no_offenses(<<~RUBY)
        params do
          requires :current_file, type: Hash, desc: "File information" do
            requires :file_name, type: String, desc: 'The name'
          end
        end
      RUBY
    end
  end

  context "when documentation is explicitly disabled" do
    it "does not register an offense for Proc in values:" do
      expect_no_offenses(<<~RUBY)
        params do
          requires :status, type: String, values: -> { Status.names }, documentation: false
        end
      RUBY
    end

    it "does not register an offense for Proc in default:" do
      expect_no_offenses(<<~RUBY)
        params do
          optional :limit, type: Integer, default: -> { Config.limit }, documentation: false
        end
      RUBY
    end
  end

  context "when documentation uses a variable" do
    it "does not register an offense for Proc in values:" do
      expect_no_offenses(<<~RUBY)
        params do
          requires :status, type: String, values: -> { Status.names }, documentation: some_documentation
        end
      RUBY
    end

    it "does not register an offense for Proc in default:" do
      expect_no_offenses(<<~RUBY)
        params do
          optional :limit, type: Integer, default: -> { Config.limit }, documentation: some_documentation
        end
      RUBY
    end
  end

  context "when Proc is assigned to a variable" do
    context "without documentation" do
      it "registers an offense for Proc variable in values:" do
        expect_offense(<<~RUBY, msg: msg_values)
          values = proc { Status.names }
          params do
            requires :status, type: String, values: values
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ %{msg}
          end
        RUBY
      end

      it "registers an offense for lambda variable in values:" do
        expect_offense(<<~RUBY, msg: msg_values)
          values = -> { Status.names }
          params do
            requires :status, type: String, values: values
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ %{msg}
          end
        RUBY
      end

      it "registers an offense for Proc variable in default:" do
        expect_offense(<<~RUBY, msg: msg_default)
          default_value = proc { Config.limit }
          params do
            optional :limit, type: Integer, default: default_value
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ %{msg}
          end
        RUBY
      end

      it "registers an offense for lambda variable in default:" do
        expect_offense(<<~RUBY, msg: msg_default)
          default_value = -> { Config.limit }
          params do
            optional :limit, type: Integer, default: default_value
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ %{msg}
          end
        RUBY
      end
    end

    context "with documentation" do
      it "does not register an offense for Proc variable in values:" do
        expect_no_offenses(<<~RUBY)
          values = proc { Status.names }
          params do
            requires :status, type: String, values: values, documentation: { example: 'active' }
          end
        RUBY
      end

      it "does not register an offense for Proc variable in default:" do
        expect_no_offenses(<<~RUBY)
          default_value = proc { Config.limit }
          params do
            optional :limit, type: Integer, default: default_value, documentation: { example: 10 }
          end
        RUBY
      end
    end

    context "when variable is not a Proc" do
      it "does not register an offense for non-Proc variable in values:" do
        expect_no_offenses(<<~RUBY)
          values = %w[active inactive]
          params do
            requires :status, type: String, values: values
          end
        RUBY
      end

      it "does not register an offense for non-Proc variable in default:" do
        expect_no_offenses(<<~RUBY)
          default_value = 10
          params do
            optional :limit, type: Integer, default: default_value
          end
        RUBY
      end
    end
  end
end
