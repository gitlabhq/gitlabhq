# frozen_string_literal: true

require "csv"
require "sidekiq"
require_relative "../helper"

describe Sidekiq::Job::Iterable::CsvEnumerator do
  it "raises if passed object is not a CSV" do
    e = assert_raises(ArgumentError) do
      build_enumerator([])
    end
    assert_equal "CsvEnumerator.new takes CSV object", e.message
  end

  describe "#rows" do
    it "yields every record with their cursor position" do
      enum = build_enumerator(products_csv).rows(cursor: nil)
      assert_instance_of Enumerator::Lazy, enum

      enum.each_with_index do |(element, cursor), index|
        assert_equal [csv_rows[index], index], [element.fields, cursor]
      end
    end

    it "can be resumed" do
      enum = build_enumerator(products_csv).rows(cursor: 3)
      assert_instance_of Enumerator::Lazy, enum

      enum.each_with_index do |(element, cursor), index|
        assert_equal [csv_rows[index + 3], index + 3], [element.fields, cursor]
      end
    end

    it "returns size excluding headers" do
      enum = build_enumerator(products_csv(headers: false)).rows(cursor: 0)
      assert_equal 12, enum.size

      enum = build_enumerator(products_csv(headers: true)).rows(cursor: 0)
      assert_equal 11, enum.size
    end

    it "returns nil count for a CSV object from a String" do
      csv_string = File.read("test/fixtures/products.csv")
      enum = build_enumerator(CSV.new(csv_string)).rows(cursor: 0)
      assert_nil enum.size
    end

    it "returns total size if resumed" do
      enum = build_enumerator(products_csv).rows(cursor: 10)
      assert_equal 11, enum.size
    end
  end

  describe "#batches" do
    it "yields every batch with their cursor position" do
      enum = build_enumerator(products_csv).batches(batch_size: 3, cursor: nil)
      assert_instance_of Enumerator::Lazy, enum

      expected_values = csv_rows.each_slice(3).to_a
      enum.each_with_index do |(element, cursor), index|
        assert_equal [expected_values[index], index], [element.map(&:fields), cursor]
      end
    end

    it "can be resumed" do
      enum = build_enumerator(products_csv).batches(batch_size: 3, cursor: 2)
      assert_instance_of Enumerator::Lazy, enum

      expected_values = csv_rows.each_slice(3).drop(2).to_a
      enum.each_with_index do |(element, cursor), index|
        assert_equal [expected_values[index], index + 2], [element.map(&:fields), cursor]
      end
    end

    it "returns size" do
      enum = build_enumerator(products_csv).batches(batch_size: 2, cursor: 0)
      assert_equal 6, enum.size

      enum = build_enumerator(products_csv).batches(batch_size: 3, cursor: 0)
      assert_equal 4, enum.size
    end

    it "returns total size if resumed" do
      enum = build_enumerator(products_csv).batches(batch_size: 2, cursor: 5)
      assert_equal 6, enum.size
    end
  end

  private

  def build_enumerator(csv)
    Sidekiq::Job::Iterable::CsvEnumerator.new(csv)
  end

  def csv_rows
    @csv_rows ||= products_csv.map(&:fields)
  end

  def products_csv(options = {})
    CSV.open("test/fixtures/products.csv", converters: :integer, headers: true, **options)
  end
end
