# frozen_string_literal: true

require "spec_helper"

RSpec.describe Authz::RedactionPolicyClassMaps, feature_category: :permissions do
  describe ".memoize" do
    it "does not memoize when no request store is active" do
      described_class.memoize do
        expect(ProjectPolicy.conditions).not_to equal(ProjectPolicy.conditions)
      end
    end

    context "with an active request store", :request_store do
      %i[conditions ability_map global_actions delegations].each do |name|
        it "returns the same #{name} object per class inside the block" do
          described_class.memoize do
            expect(ProjectPolicy.public_send(name)).to equal(ProjectPolicy.public_send(name))
            expect(ProjectPolicy.public_send(name)).not_to equal(GroupPolicy.public_send(name))
          end
        end

        it "rebuilds #{name} on every call outside the block" do
          expect(ProjectPolicy.public_send(name)).not_to equal(ProjectPolicy.public_send(name))
        end
      end

      it "shares the maps with a nested block and keeps memoizing after it" do
        described_class.memoize do
          outer = ProjectPolicy.conditions

          described_class.memoize { expect(ProjectPolicy.conditions).to equal(outer) }

          expect(ProjectPolicy.conditions).to equal(outer)
        end
      end

      it "does not keep maps across blocks" do
        first = described_class.memoize { ProjectPolicy.conditions }
        second = described_class.memoize { ProjectPolicy.conditions }

        expect(first).not_to equal(second)
        expect(first).to eq(second)
      end

      it "stops memoizing when the block raises" do
        expect { described_class.memoize { raise "boom" } }.to raise_error("boom")
        expect(ProjectPolicy.conditions).not_to equal(ProjectPolicy.conditions)
      end
    end
  end
end
