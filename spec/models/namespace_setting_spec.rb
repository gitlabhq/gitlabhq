# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NamespaceSetting, type: :model do
  # Relationships
  #
  it { is_expected.to belong_to(:namespace) }

  describe "validations" do
    describe "#default_branch_name_content" do
      let_it_be(:group) { create(:group) }

      let(:namespace_settings) { group.namespace_settings }

      shared_examples "doesn't return an error" do
        it "doesn't return an error" do
          expect(namespace_settings.valid?).to be_truthy
          expect(namespace_settings.errors.full_messages).to be_empty
        end
      end

      context "when not set" do
        it_behaves_like "doesn't return an error"
      end

      context "when set" do
        before do
          namespace_settings.default_branch_name = "example_branch_name"
        end

        it_behaves_like "doesn't return an error"
      end

      context "when an empty string" do
        before do
          namespace_settings.default_branch_name = ''
        end

        it "returns an error" do
          expect(namespace_settings.valid?).to be_falsey
          expect(namespace_settings.errors.full_messages).not_to be_empty
        end
      end
    end
  end
end
