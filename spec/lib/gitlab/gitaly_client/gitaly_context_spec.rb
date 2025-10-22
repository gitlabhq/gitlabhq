# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GitalyClient::GitalyContext, feature_category: :source_code_management do
  context 'with request store', :request_store do
    describe '.current_context and .with_context' do
      specify "stacking and scope", :aggregate_failures do
        expect(described_class.current_context).to be_empty
        expect(described_class.current_context).to be_frozen

        described_class.with_context("key_1" => 1) do
          expect(described_class.current_context).to eq({ "key_1" => 1 }) { "With context adds to context" }
          expect(described_class.current_context).to be_frozen { "New contexts are frozen" }

          described_class.with_context("key_2" => 2, :key_3 => 3) do
            expect(described_class.current_context).to eq({ "key_1" => 1, "key_2" => 2, "key_3" => 3 }) {
              "Context is with indifferent access"
            }

            described_class.with_context("key_1" => 1, "key_2" => "override") do
              expect(described_class.current_context).to eq({ "key_1" => 1, "key_2" => "override", "key_3" => 3 }) {
                "Shadowing: Values can be shadowed within a block"
              }
            end

            expect(described_class.current_context).to eq({ "key_1" => 1, "key_2" => 2, "key_3" => 3 }) {
              "Shadowing: End of block restores previous value"
            }

            expected_object_id = described_class.current_context.object_id
            described_class.with_context("key_1" => 1, "key_2" => 2) do
              expect(described_class.current_context.object_id).to eq(expected_object_id) {
                "Contexts are only allocated as needed"
              }
            end
          end

          expect(described_class.current_context).to eq({ "key_1" => 1 }) {
            "Entries are popped when they go out of scope"
          }
        end

        expect(described_class.current_context).to be_empty
      end
    end
  end
end
