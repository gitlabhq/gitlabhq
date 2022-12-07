# frozen_string_literal: true

require 'fast_spec_helper'
require 'support/helpers/rails_helpers'
require 'rspec-parameterized'

RSpec.describe Gitlab::Instrumentation::RedisClusterValidator do
  include RailsHelpers

  describe '.validate' do
    using RSpec::Parameterized::TableSyntax

    where(:command, :arguments, :keys, :is_valid) do
      :rename | %w(foo bar) | 2 | false
      :RENAME | %w(foo bar) | 2 | false
      'rename' | %w(foo bar) | 2 | false
      'RENAME' | %w(foo bar) | 2 | false
      :rename | %w(iaa ahy) | 2 | true # 'iaa' and 'ahy' hash to the same slot
      :rename | %w({foo}:1 {foo}:2) | 2 | true
      :rename | %w(foo foo bar) | 2 | true # This is not a valid command but should not raise here
      :mget | %w(foo bar) | 2 | false
      :mget | %w(foo foo bar) | 3 | false
      :mget | %w(foo foo) | 2 | true
      :blpop | %w(foo bar 1) | 2 | false
      :blpop | %w(foo foo 1) | 2 | true
      :mset | %w(foo a bar a) | 2 | false
      :mset | %w(foo a foo a) | 2 | true
      :del | %w(foo bar) | 2 | false
      :del | [%w(foo bar)] | 2 | false # Arguments can be a nested array
      :del | %w(foo foo) | 2 | true
      :hset | %w(foo bar) | 1 | nil # Single key write
      :get | %w(foo) | 1 | nil # Single key read
      :mget | [] | 0 | true # This is invalid, but not because it's a cross-slot command
    end

    with_them do
      it do
        args = [[command] + arguments]
        if is_valid.nil?
          expect(described_class.validate(args, true)).to eq(nil)
        else
          expect(described_class.validate(args, true)[:valid]).to eq(is_valid)
          expect(described_class.validate(args, true)[:allowed]).to eq(false)
          expect(described_class.validate(args, true)[:command_name]).to eq(command.to_s.upcase)
          expect(described_class.validate(args, true)[:key_count]).to eq(keys)
        end
      end
    end

    where(:arguments, :should_raise, :output) do
      [
        [
          [[:get, "foo"], [:get, "bar"]],
          true,
          { valid: false, key_count: 2, command_name: 'PIPELINE/MULTI', allowed: false, command: "get foo" }
        ],
        [
          [[:get, "foo"], [:mget, "foo", "bar"]],
          true,
          { valid: false, key_count: 3, command_name: 'PIPELINE/MULTI', allowed: false, command: "get foo" }
        ],
        [
          [[:get, "{foo}:name"], [:get, "{foo}:profile"]],
          false,
          { valid: true, key_count: 2, command_name: 'PIPELINE/MULTI', allowed: false, command: "get {foo}:name" }
        ],
        [
          [[:del, "foo"], [:del, "bar"]],
          true,
          { valid: false, key_count: 2, command_name: 'PIPELINE/MULTI', allowed: false, command: "del foo" }
        ],
        [
          [],
          false,
          nil # pipeline or transaction opened and closed without ops
        ]
      ]
    end

    with_them do
      it do
        expect(described_class.validate(arguments, true)).to eq(output)
      end
    end
  end

  describe '.allow_cross_slot_commands' do
    context 'with validate_allowed_cmd set to true' do
      it 'runs validation for allowed commands' do
        expect(
          described_class.allow_cross_slot_commands do
            described_class.validate([[:mget, 'foo', 'bar']], true)
          end
        ).to eq({ valid: false, key_count: 2, command_name: 'MGET', allowed: true,
                  command: "mget foo bar" })
      end

      it 'allows nested invocation' do
        expect(
          described_class.allow_cross_slot_commands do
            described_class.allow_cross_slot_commands do
              described_class.validate([[:mget, 'foo', 'bar']], true)
            end

            described_class.validate([[:mget, 'foo', 'bar']], true)
          end
        ).to eq({ valid: false, key_count: 2, command_name: 'MGET', allowed: true,
                  command: "mget foo bar" })
      end
    end

    context 'with validate_allowed_cmd set to false' do
      it 'does not run for allowed commands' do
        expect(
          described_class.allow_cross_slot_commands do
            described_class.validate([[:mget, 'foo', 'bar']], false)
          end
        ).to eq(nil)
      end
    end
  end
end
