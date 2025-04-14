# frozen_string_literal: true

require "csv"
require "active_record"
require "sidekiq"
require_relative "../helper"
require_relative "../dummy/config/environment"

class Product < ActiveRecord::Base
end

describe Sidekiq::Job::Iterable::ActiveRecordEnumerator do
  before(:all) do
    Product.connection.create_table(:products, force: true)
    products = [9, 1, 3, 2, 7, 6, 4, 5, 8, 10].map { |id| {id: id} }
    Product.insert_all!(products)
  end

  describe "#records" do
    it "yields every record with their cursor position" do
      enum = build_enumerator.records
      assert_equal Product.count, enum.size

      products = Product.order(:id).take(3)
      enum.first(3).each_with_index do |(record, cursor), index|
        product = products[index]
        assert_equal product, record
        assert_equal product.id, cursor
      end
    end

    it "does not yield anything if the relation is empty" do
      enum = build_enumerator(relation: Product.none).records

      assert_empty enum.to_a
      assert_equal 0, enum.size
    end

    it "can be resumed" do
      enum = build_enumerator(cursor: Product.second.id).records
      assert_equal Product.count, enum.size

      products = Product.order(:id).offset(1).take(3)
      enum.first(3).each_with_index do |(record, cursor), index|
        product = products[index]
        assert_equal product, record
        assert_equal product.id, cursor
      end
    end
  end

  describe "#batches" do
    it "yields batches of records with the first record's cursor position" do
      enum = build_enumerator.batches
      assert_equal 10, enum.size

      products = Product.order(:id).take(4).each_slice(2).to_a

      enum.first(2).each_with_index do |(batch, cursor), index|
        expected_batch = products[index]
        expected_cursor = expected_batch.first.id
        assert_equal expected_batch, batch
        assert_equal expected_cursor, cursor
      end
    end

    it "does not yield anything if the relation is empty" do
      enum = build_enumerator(relation: Product.none).batches
      assert_empty enum.to_a
    end

    it "can be resumed" do
      enum = build_enumerator(cursor: Product.second.id).batches
      assert_equal 10, enum.size

      products = Product.order(:id).offset(1).take(4).each_slice(2).to_a

      enum.first(2).each_with_index do |(batch, cursor), index|
        expected_records = products[index]
        expected_cursor = expected_records.first.id
        assert_equal expected_records, batch
        assert_equal expected_cursor, cursor
      end
    end
  end

  describe "#relations" do
    it "yields relations with the first record's cursor position" do
      enum = build_enumerator.relations
      assert_equal 5, enum.size

      product_batches = Product.order(:id).take(4).in_groups_of(2)

      enum.first(2).each_with_index do |(relation, cursor), index|
        assert_kind_of ActiveRecord::Relation, relation

        expected_records = product_batches[index]
        expected_cursor = expected_records.first.id
        assert_equal expected_records, relation.to_a
        assert_equal expected_cursor, cursor
      end
    end

    it "yields unloaded relations" do
      enum = build_enumerator.relations
      relation, = enum.first

      refute relation.loaded?
    end

    it "does not yield anything if the relation is empty" do
      enum = build_enumerator(relation: Product.none).relations
      assert_empty enum.to_a
    end

    it "can be resumed" do
      enum = build_enumerator(cursor: Product.second.id).relations
      assert_equal 5, enum.size

      product_batches = Product.order(:id).offset(1).take(4).in_groups_of(2)

      enum.first(2).each_with_index do |(relation, cursor), index|
        assert_kind_of ActiveRecord::Relation, relation

        expected_records = product_batches[index]
        expected_cursor = expected_records.first.id
        assert_equal expected_records, relation.to_a
        assert_equal expected_cursor, cursor
      end
    end
  end

  private

  def build_enumerator(relation: Product.all, batch_size: 2, cursor: nil)
    Sidekiq::Job::Iterable::ActiveRecordEnumerator.new(relation, batch_size: batch_size, cursor: cursor)
  end
end
