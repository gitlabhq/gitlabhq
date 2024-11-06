# frozen_string_literal: true

require "spec_helper"

RSpec.describe Import::PlaceholderReferences::AliasResolver, feature_category: :importers do
  describe ".aliases" do
    def missing_attribute_message(model, attribute)
      <<-MSG
        #{model}##{attribute} references a user and it is not defined in #{described_class}::ALIASES.
        Please add the attribute in the columns key in the #{described_class}::ALIASES['#{model}'] hash.
      MSG
    end

    def missing_alias_message(model)
      <<-MSG
        #{model} models references a user and it is not defined in #{described_class}::ALIASES.
        Please define the mapping in #{described_class}::ALIASES.
      MSG
    end

    it "points to real columns" do
      def failure_message(model, column)
        <<-MSG
          The column #{model}.#{column} no longer exists. Please update #{described_class}::ALIASES
          to point to the new column name so that importers can continue to process old data correctly
          during user mapping.
        MSG
      end

      described_class.aliases.each_value.flat_map(&:values).each do |model_alias|
        model = model_alias[:model]
        column_names = model.columns.map(&:name)

        model_alias[:columns].each_value do |value|
          expect(column_names).to include(value), failure_message(model, value)
        end
      end
    end

    it 'contains deletion exclusions for un-indexed columns', :aggregate_failures do
      def failure_message(model, column)
        <<-MSG
          ALIASES["#{model}"] contains a user reference without a database index. This can cause
          performance issues when checking for placeholder contributions. Please update
          the `columns_ignored_on_deletion` field on ALIASES["#{model}"] to include '#{column}'.
        MSG
      end

      described_class.aliases.each_value.flat_map(&:values).each do |model_alias|
        model = model_alias[:model]
        indexes = ApplicationRecord.connection.indexes(model.table_name).map { |i| i.columns.first }.uniq

        model_alias[:columns].each_value do |column|
          next if Gitlab::ImportExport::Base::RelationFactory::USER_REFERENCES.exclude?(column)
          next if indexes.include?(column)

          expect(model_alias[:columns_ignored_on_deletion].to_a).to include(column),
            failure_message(model_alias[:model], column)
        end
      end
    end

    shared_examples 'define aliases' do
      def relation_class(relation_key)
        relation_key.to_s.classify.constantize
      rescue NameError
        relation_key.to_s.constantize
      end

      def extract_relation_names(hash, keys = [])
        keys += hash.keys
        hash.each_value do |value|
          keys += extract_relation_names(value, keys)
        end
        keys.uniq
      end

      it "defines aliases for imported resources that references users", :eager_load do
        relation_names = extract_relation_names(config_tree).reject { |name| ignore_relations.include?(name) }
        relation_names.each do |relation_name|
          relation_name = overrides[relation_name] || relation_name
          model_class = relation_class(relation_name)
          table_columns = model_class.columns.collect(&:name)
          user_associations = model_class.reflect_on_all_associations(:belongs_to)
            .reject(&:polymorphic?)
            .filter { |association| association.klass == User }
            .reject { |association| table_columns.exclude?(association.foreign_key) }

          next unless user_associations.any?

          expect(described_class.aliases[model_class.to_s]).to be_present, missing_alias_message(model_class)

          user_associations.each do |association|
            foreign_key = association.foreign_key
            last_version = described_class.aliases[model_class.to_s].keys.max
            alias_definition = described_class.aliases[model_class.to_s][last_version]
            expect(alias_definition[:columns]).to include(foreign_key),
              missing_attribute_message(model_class, foreign_key)
          end
        end
      end
    end

    describe 'group aliases' do
      let(:overrides) { Gitlab::ImportExport::Group::RelationFactory.overrides }
      let(:ignore_relations) { %i[members user_contributions author user] }
      let(:config_tree) do
        Gitlab::ImportExport::Config.new(config: Gitlab::ImportExport.group_config_file).to_h[:tree][:group]
      end

      it_behaves_like 'define aliases'
    end

    describe 'project aliases' do
      let(:overrides) { Gitlab::ImportExport::Project::RelationFactory.overrides }
      let(:ignore_relations) { %i[project_members user_contributions author user] }
      let(:config_tree) do
        Gitlab::ImportExport::Config.new(config: Gitlab::ImportExport.config_file).to_h[:tree][:project]
      end

      it_behaves_like 'define aliases'
    end

    it "defines aliases for all note descendants apart from synthetic notes" do
      user_associations = Note.reflect_on_all_associations(:belongs_to)
        .reject(&:polymorphic?)
        .filter { |association| association.klass == User }
        .reject { |association| Note.columns.collect(&:name).exclude?(association.foreign_key) }

      (Note.descendants - SyntheticNote.descendants - [SyntheticNote]).each do |descendant|
        expect(described_class.aliases[descendant.to_s]).to be_present, missing_alias_message(descendant)

        user_associations.each do |association|
          foreign_key = association.foreign_key
          last_version = described_class.aliases[descendant.to_s].keys.max
          alias_definition = described_class.aliases[descendant.to_s][last_version]
          expect(alias_definition[:columns]).to include(foreign_key),
            missing_attribute_message(descendant, foreign_key)
        end
      end
    end
  end

  describe ".version_for_model" do
    let(:aliases) do
      {
        "Note" => {
          1 => {
            model: Note,
            columns: { "author_id" => "author_id" }
          },
          2 => {
            model: Note,
            columns: { "author_id" => "user_id" }
          }
        }
      }
    end

    before do
      allow(described_class).to receive(:aliases).and_return(aliases)
    end

    it "returns the max version available for the model" do
      expect(described_class.version_for_model("Note")).to eq(2)
    end

    context "when the model does not exist" do
      it "returns version 1 after reporting a missing alias" do
        expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception)
          .with(described_class::MissingAlias.new("ALIASES must be extended to include Issue"))

        expect(described_class.version_for_model("Issue")).to eq(1)
      end
    end
  end

  describe ".aliased_model" do
    subject(:aliased_model) { described_class.aliased_model(model, version: 1) }

    let(:model) { "Note" }

    context "when model exists" do
      it "returns the model" do
        expect(aliased_model).to eq(Note)
      end
    end

    context "when there are multiple versions" do
      let(:aliases) do
        {
          "Note" => {
            1 => { model: Note, columns: { "author_id" => "author_id" } },
            2 => { model: Issue, columns: { "author_id" => "author_id" } }
          }
        }
      end

      before do
        allow(described_class).to receive(:aliases).and_return(aliases)
      end

      it "returns the value for the right version" do
        expect(described_class.aliased_model(model, version: 1)).to eq(Note)
        expect(described_class.aliased_model(model, version: 2)).to eq(Issue)
      end
    end

    context "when the model has changed" do
      let(:model) { "Description" }

      let(:aliases) do
        {
          "Description" => {
            1 => {
              model: Note,
              columns: {
                "author_id" => "author_id"
              }
            }
          }
        }
      end

      before do
        allow(described_class).to receive(:aliases).and_return(aliases)
      end

      it "returns the new model name" do
        expect(aliased_model).to eq(Note)
      end
    end

    context "when requesting an unknown model" do
      let(:model) { "Blob" }

      it "returns a constantized version of the passed string after reporting a missing alias" do
        expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception).with(
          described_class::MissingAlias.new("ALIASES must be extended to include Blob for version 1")
        )

        expect(aliased_model).to eq(Blob)
      end
    end

    context "when requesting a model that doesn't exist" do
      let(:model) { "NotARealModel" }

      it "raises a MissingAlias error and reports it" do
        expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception).with(
          described_class::MissingAlias.new("ALIASES must be extended to include NotARealModel for version 1")
        )

        expect { aliased_model }.to raise_exception(described_class::MissingAlias)
          .with_message("ALIASES must be extended to include NotARealModel for version 1")
      end
    end
  end

  describe ".aliased_column" do
    subject(:aliased_column) { described_class.aliased_column(model, column, version: 1) }

    let(:model) { "Note" }
    let(:column) { "author_id" }

    it "returns the column" do
      expect(aliased_column).to eq("author_id")
    end

    context "when there are multiple versions" do
      let(:aliases) do
        {
          "Note" => {
            1 => { model: Note, columns: { "author_id" => "author_id" } },
            2 => { model: Issue, columns: { "author_id" => "user_id" } }
          }
        }
      end

      before do
        allow(described_class).to receive(:aliases).and_return(aliases)
      end

      it "returns the value for the right version" do
        expect(described_class.aliased_column(model, column, version: 1)).to eq("author_id")
        expect(described_class.aliased_column(model, column, version: 2)).to eq("user_id")
      end
    end

    context "when the column has changed" do
      let(:aliases) do
        {
          "Note" => {
            1 => {
              model: Note,
              columns: {
                "author_id" => "user_id"
              }
            }
          }
        }
      end

      before do
        allow(described_class).to receive(:aliases).and_return(aliases)
      end

      it "returns the new column name" do
        expect(aliased_column).to eq("user_id")
      end
    end

    context "when the column doesn't exist" do
      let(:column) { "test123_id" }

      it "returns the same column after reporting a missing alias" do
        expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception).with(
          described_class::MissingAlias.new("ALIASES must be extended to include Note.test123_id for version 1")
        )

        expect(aliased_column).to eq("test123_id")
      end
    end
  end

  describe ".models_with_data" do
    subject(:models_with_data) { described_class.models_with_data }

    it "returns models with all their columns" do
      expect(models_with_data).to include([Approval, {
        model: Approval,
        columns: { "user_id" => "user_id" }
      }])
    end

    context "when there are multiple versions for a key" do
      let(:aliases) do
        {
          "Note" => {
            1 => {
              model: Note,
              columns: { "author_id" => "author_id" }
            },
            2 => {
              model: Note,
              columns: { "author_id" => "user_id" }
            }
          }
        }
      end

      before do
        allow(described_class).to receive(:aliases).and_return(aliases)
      end

      it "only includes the last version" do
        _model, data = models_with_data.first
        columns = data[:columns].values

        expect(columns).to include('user_id')
        expect(columns).not_to include('author_id')
      end
    end
  end
end
