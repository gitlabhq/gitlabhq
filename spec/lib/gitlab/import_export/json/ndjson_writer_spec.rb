# frozen_string_literal: true

require "spec_helper"

RSpec.describe Gitlab::ImportExport::Json::NdjsonWriter do
  include ImportExport::CommonUtil

  let(:path) { "#{Dir.tmpdir}/ndjson_writer_spec/tree" }
  let(:exportable_path) { 'projects' }

  subject { described_class.new(path) }

  after do
    FileUtils.rm_rf(path)
  end

  describe "#write_attributes" do
    it "writes correct json to root" do
      expected_hash = { "key" => "value_1", "key_1" => "value_2" }
      subject.write_attributes(exportable_path, expected_hash)

      expect(consume_attributes(path, exportable_path)).to eq(expected_hash)
    end
  end

  describe "#write_relation" do
    context "when single relation is serialized" do
      it "appends json in correct file" do
        relation = "relation"
        value =  { "key" => "value_1", "key_1" => "value_1" }
        subject.write_relation(exportable_path, relation, value)

        expect(consume_relations(path, exportable_path, relation)).to eq([value])
      end
    end

    context "when single relation is already serialized" do
      it "raise exception" do
        values = [{ "key" => "value_1", "key_1" => "value_1" }, { "key" => "value_2", "key_1" => "value_2" }]
        relation = "relation"
        file_path = File.join(path, exportable_path, "#{relation}.ndjson")
        subject.write_relation(exportable_path, relation, values[0])

        expect {subject.write_relation(exportable_path, relation, values[1])}.to raise_exception("The #{file_path} already exist")
      end
    end
  end

  describe "#write_relation_array" do
    it "writes json in correct files" do
      values =  [{ "key" => "value_1", "key_1" => "value_1" }, { "key" => "value_2", "key_1" => "value_2" }]
      relations = %w(relation1 relation2)
      relations.each do |relation|
        subject.write_relation_array(exportable_path, relation, values.to_enum)
      end
      subject.close

      relations.each do |relation|
        expect(consume_relations(path, exportable_path, relation)).to eq(values)
      end
    end
  end
end
