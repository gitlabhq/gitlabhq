# frozen_string_literal: true

require "fast_spec_helper"
require_relative '../../../../support/matchers/result_matchers'

RSpec.describe Gitlab::Fp::Settings::EnvVarOverrideProcessor, feature_category: :shared do
  include ResultMatchers

  let(:default_setting_value) { 42 }
  let(:setting_name) { 'the_setting' }
  let(:setting_type) { Integer }
  let(:env_var_prefix) { "THE_PREFIX" }
  let(:env_var_failed_message_class) { Class.new(Gitlab::Fp::Message) }
  let(:env_var_name) { "#{env_var_prefix}_#{setting_name.upcase}" }
  let(:rails_env_is_production) { false }
  let(:context) do
    {
      settings: {
        "#{setting_name}": default_setting_value
      },
      setting_types: {
        "#{setting_name}": setting_type
      },
      env_var_prefix: env_var_prefix,
      env_var_failed_message_class: env_var_failed_message_class
    }
  end

  subject(:result) do
    described_class.process(context)
  end

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with(env_var_name) { env_var_value }
    allow(Rails).to receive_message_chain(:env, :production?) { rails_env_is_production }
  end

  context "when an ENV var overrides a default setting" do
    context "when setting_type is String" do
      let(:env_var_value) { "a string" }
      let(:setting_type) { String }

      it "uses the string value of the overridden ENV var value" do
        expect(result).to be_ok_result(
          {
            settings: { the_setting: env_var_value },
            setting_types: { the_setting: setting_type },
            env_var_prefix: env_var_prefix,
            env_var_failed_message_class: env_var_failed_message_class
          }
        )
      end
    end

    context "when setting_type is Integer" do
      let(:env_var_value) { "999" }
      let(:setting_type) { Integer }

      it "uses the casted type of the overridden ENV var value" do
        expect(result).to eq(Gitlab::Fp::Result.ok(
          {
            settings: { the_setting: env_var_value.to_i },
            setting_types: { the_setting: setting_type },
            env_var_prefix: env_var_prefix,
            env_var_failed_message_class: env_var_failed_message_class
          }
        ))
      end
    end

    context "when setting_type is :Boolean" do
      let(:setting_type) { :Boolean }

      context "for true value" do
        let(:env_var_value) { "true" }

        it "uses the casted type of the overridden ENV var value" do
          expect(result).to eq(Gitlab::Fp::Result.ok(
            {
              settings: { the_setting: true },
              setting_types: { the_setting: setting_type },
              env_var_prefix: env_var_prefix,
              env_var_failed_message_class: env_var_failed_message_class
            }
          ))
        end
      end

      context "for false value" do
        let(:env_var_value) { "false" }

        it "uses the casted type of the overridden ENV var value" do
          expect(result).to eq(Gitlab::Fp::Result.ok(
            {
              settings: { the_setting: false },
              setting_types: { the_setting: setting_type },
              env_var_prefix: env_var_prefix,
              env_var_failed_message_class: env_var_failed_message_class
            }
          ))
        end
      end
    end

    context "when setting_type is Hash" do
      let(:env_var_value) { '{"a": 1}' }
      let(:setting_type) { Hash }

      it "uses the casted type of the overridden ENV var value" do
        expect(result).to eq(Gitlab::Fp::Result.ok(
          {
            settings: { the_setting: { a: 1 } },
            setting_types: { the_setting: setting_type },
            env_var_prefix: env_var_prefix,
            env_var_failed_message_class: env_var_failed_message_class
          }
        ))
      end
    end

    context "when setting_type is Array" do
      let(:env_var_value) { '["a", 1]' }
      let(:setting_type) { Array }

      it "uses the casted type of the overridden ENV var value" do
        expect(result).to eq(Gitlab::Fp::Result.ok(
          {
            settings: { the_setting: ["a", 1] },
            setting_types: { the_setting: setting_type },
            env_var_prefix: env_var_prefix,
            env_var_failed_message_class: env_var_failed_message_class
          }
        ))
      end
    end
  end

  context "when an ENV matches the pattern but there is no matching default setting value defined" do
    let(:env_var_name) { "#{env_var_prefix}_NONEXISTENT_SETTING" }
    let(:env_var_value) { "maybe some old deprecated setting, doesn't matter, it's ignored" }

    it "ignores the ENV var" do
      expect(result).to eq(Gitlab::Fp::Result.ok(
        {
          settings: { the_setting: default_setting_value },
          setting_types: { the_setting: setting_type },
          env_var_prefix: env_var_prefix,
          env_var_failed_message_class: env_var_failed_message_class
        }
      ))
    end
  end

  context "when ENV var contains an incorrect type" do
    context "for Integer type setting" do
      let(:env_var_value) { "not an Integer type" }
      let(:setting_type) { Integer }

      it "returns an err Result containing a settings environment variable failed message with details" do
        expect(result).to be_err_result(
          env_var_failed_message_class.new(
            details: "ENV var '#{env_var_name}' value could not be cast to #{setting_type} type."
          )
        )
      end
    end

    context "for :Boolean type setting" do
      let(:env_var_value) { "not a :Boolean type" }
      let(:setting_type) { :Boolean }

      it "returns an err Result containing a settings environment variable failed message with details" do
        expect(result).to be_err_result(
          env_var_failed_message_class.new(
            details: "ENV var '#{env_var_name}' value could not be cast to boolean type, " \
              "value must be 'true' or 'false'"
          )
        )
      end
    end

    context "for Hash type setting" do
      let(:setting_type) { Hash }

      context "with invalid JSON" do
        let(:env_var_value) { "not a JSON string that can be converted to a Hash" }

        it "returns an err Result containing a settings environment variable failed message with details" do
          expect(result).to be_err_result do |message|
            expect(message).to be_a(env_var_failed_message_class)
            message.content => { details: String => details }
            expect(details).to match(
              /ENV var '#{env_var_name}'.*not valid parseable JSON. Parse error was: 'not a number.*line 1, column 1.*'/
            )
          end
        end
      end

      context "with JSON that is an Array" do
        let(:env_var_value) { "[1]" }

        it "returns an err Result containing a settings environment variable failed message with details" do
          expect(result).to be_err_result do |message|
            expect(message).to be_a(env_var_failed_message_class)
            message.content => { details: String => details }
            expect(details).to match(
              /ENV var '#{env_var_name}' was a JSON array type, but it should be an object type/
            )
          end
        end
      end
    end

    context "for Array type setting" do
      let(:setting_type) { Array }

      context "with invalid JSON" do
        let(:env_var_value) { "not a JSON string that can be converted to an Array" }

        it "returns an err Result containing a settings environment variable failed message with details" do
          expect(result).to be_err_result do |message|
            expect(message).to be_a(env_var_failed_message_class)
            message.content => { details: String => details }
            expect(details).to match(
              /ENV var '#{env_var_name}'.*not valid parseable JSON. Parse error was: 'not a number.*line 1, column 1.*'/
            )
          end
        end

        context "with JSON that is a Hash" do
          let(:env_var_value) { '{"a": 1}' }

          it "returns an err Result containing a settings environment variable failed message with details" do
            expect(result).to be_err_result do |message|
              expect(message).to be_a(env_var_failed_message_class)
              message.content => { details: String => details }
              expect(details).to match(
                /ENV var '#{env_var_name}' was a JSON object type, but it should be an array type/
              )
            end
          end
        end
      end
    end
  end

  context "when setting_type is an unsupported type" do
    let(:env_var_value) { "42" }
    let(:setting_type) { Float }

    it "returns an err Result containing a settings environment variable failed message with details" do
      expect(result).to be_err_result(
        env_var_failed_message_class.new(details: "Unsupported setting type: #{setting_type}")
      )
    end
  end

  context "when Rails env is production" do
    let(:rails_env_is_production) { true }

    it 'does not change any context' do
      expect(result).to eq Gitlab::Fp::Result.ok(context)
    end
  end
end
