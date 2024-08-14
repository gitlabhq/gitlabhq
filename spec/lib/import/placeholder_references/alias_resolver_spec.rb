# frozen_string_literal: true

require "spec_helper"

RSpec.describe Import::PlaceholderReferences::AliasResolver, feature_category: :importers do
  describe "ALIASES" do
    it "points to real columns" do
      def failure_message(model, column)
        <<-MSG
          The column #{model}.#{column} no longer exists. Please update #{described_class}::ALIASES
          to point to the new column name so that importers can continue to process old data correctly
          during user mapping.
        MSG
      end

      described_class::ALIASES.each_value do |model_alias|
        model = model_alias[:model]
        column_names = model.columns.map(&:name)

        model_alias[:columns].each_value do |value|
          expect(column_names).to include(value), failure_message(model, value)
        end
      end
    end
  end

  describe ".aliased_model" do
    subject(:aliased_model) { described_class.aliased_model(model) }

    context "when model exists" do
      let(:model) { "Note" }

      it "returns the model" do
        expect(aliased_model).to eq(Note)
      end
    end

    context "when the model has changed" do
      let(:model) { "Description" }

      let(:aliases) do
        {
          "Description" => {
            model: Note,
            columns: {
              "author_id" => "author_id"
            }
          }
        }
      end

      before do
        stub_const("#{described_class}::ALIASES", aliases)
      end

      it "returns the new model name" do
        expect(aliased_model).to eq(Note)
      end
    end

    context "when requesting an unknown model" do
      let(:model) { "Blob" }

      it "returns a constantized version of the passed string after reporting a missing alias" do
        expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception)
          .with(described_class::MissingAlias)

        expect(aliased_model).to eq(Blob)
      end
    end

    context "when requesting a model that doesn't exist" do
      let(:model) { "NotARealModel" }

      it "returns nil after reporting a missing alias" do
        expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception)
          .with(described_class::MissingAlias)

        expect(aliased_model).to be_nil
      end
    end
  end

  describe ".aliased_column" do
    subject(:aliased_column) { described_class.aliased_column(model, column) }

    let(:model) { "Note" }
    let(:column) { "author_id" }

    it "returns the column" do
      expect(aliased_column).to eq("author_id")
    end

    context "when the column has changed" do
      let(:aliases) do
        {
          "Note" => {
            model: Note,
            columns: {
              "author_id" => "user_id"
            }
          }
        }
      end

      before do
        stub_const("#{described_class}::ALIASES", aliases)
      end

      it "returns the new column name" do
        expect(aliased_column).to eq("user_id")
      end
    end

    context "when the column doesn't exist" do
      let(:column) { "test123_id" }

      it "returns the same column after reporting a missing alias" do
        expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception)
          .with(described_class::MissingAlias)

        expect(aliased_column).to eq("test123_id")
      end
    end
  end
end
