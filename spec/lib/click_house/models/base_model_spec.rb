# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ClickHouse::Models::BaseModel, feature_category: :database do
  let(:table_name) { "dummy_table" }
  let(:query_builder) { instance_double("ClickHouse::QueryBuilder") }
  let(:updated_query_builder) { instance_double("ClickHouse::QueryBuilder") }

  let(:dummy_class) do
    Class.new(described_class) do
      def self.table_name
        "dummy_table"
      end
    end
  end

  describe '#to_sql' do
    it 'delegates to the query builder' do
      expect(query_builder).to receive(:to_sql).and_return("SELECT * FROM dummy_table")

      dummy_instance = dummy_class.new(query_builder)

      expect(dummy_instance.to_sql).to eq("SELECT * FROM dummy_table")
    end
  end

  describe '#where' do
    it 'returns a new instance with refined query' do
      dummy_instance = dummy_class.new(query_builder)

      expect(query_builder).to receive(:where).with({ foo: "bar" }).and_return(updated_query_builder)

      new_instance = dummy_instance.where(foo: "bar")

      expect(new_instance).to be_a(dummy_class)
      expect(new_instance).not_to eq(dummy_instance)
    end
  end

  describe '#order' do
    it 'returns a new instance with an order clause' do
      dummy_instance = dummy_class.new(query_builder)

      expect(query_builder).to receive(:order).with(:created_at, :asc).and_return(updated_query_builder)

      new_instance = dummy_instance.order(:created_at)

      expect(new_instance).to be_a(dummy_class)
      expect(new_instance).not_to eq(dummy_instance)
    end

    context "when direction is also passed" do
      it 'returns a new instance with an order clause' do
        dummy_instance = dummy_class.new(query_builder)

        expect(query_builder).to receive(:order).with(:created_at, :desc).and_return(updated_query_builder)

        new_instance = dummy_instance.order(:created_at, :desc)

        expect(new_instance).to be_a(dummy_class)
        expect(new_instance).not_to eq(dummy_instance)
      end
    end
  end

  describe '#limit' do
    it 'returns a new instance with a limit clause' do
      dummy_instance = dummy_class.new(query_builder)

      expect(query_builder).to receive(:limit).with(10).and_return(updated_query_builder)

      new_instance = dummy_instance.limit(10)

      expect(new_instance).to be_a(dummy_class)
      expect(new_instance).not_to eq(dummy_instance)
    end
  end

  describe '#offset' do
    it 'returns a new instance with an offset clause' do
      dummy_instance = dummy_class.new(query_builder)

      expect(query_builder).to receive(:offset).with(5).and_return(updated_query_builder)

      new_instance = dummy_instance.offset(5)

      expect(new_instance).to be_a(dummy_class)
      expect(new_instance).not_to eq(dummy_instance)
    end
  end

  describe '#group' do
    it 'returns a new instance with grouped results' do
      dummy_instance = dummy_class.new(query_builder)

      expect(query_builder).to receive(:group).with(:id, :name).and_return(updated_query_builder)

      new_instance = dummy_instance.group(:id, :name)

      expect(new_instance).to be_a(dummy_class)
      expect(new_instance).not_to eq(dummy_instance)
    end
  end

  describe '#select' do
    it 'returns a new instance with selected fields' do
      dummy_instance = dummy_class.new(query_builder)

      expect(query_builder).to receive(:select).with(:id, :name).and_return(updated_query_builder)

      new_instance = dummy_instance.select(:id, :name)

      expect(new_instance).to be_a(dummy_class)
      expect(new_instance).not_to eq(dummy_instance)
    end
  end

  describe '.table_name' do
    it 'raises a NotImplementedError for the base model' do
      expect do
        described_class.table_name
      end.to raise_error(NotImplementedError, "Subclasses must define a `table_name` class method")
    end

    it 'does not raise an error for the subclass' do
      expect(dummy_class.table_name).to eq(table_name)
    end
  end
end
