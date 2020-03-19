# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::ImportExport::JSON::LegacyWriter do
  let(:path) { "#{Dir.tmpdir}/legacy_writer_spec/test.json" }

  subject { described_class.new(path) }

  after do
    FileUtils.rm_rf(path)
  end

  describe "#write" do
    context "when key is already written" do
      it "raises exception" do
        key = "key"
        value = "value"
        subject.write(key, value)

        expect { subject.write(key, "new value") }.to raise_exception("key '#{key}' already written")
      end
    end

    context "when key is not already written" do
      context "when multiple key value pairs are stored" do
        it "writes correct json" do
          expected_hash = { "key" => "value_1", "key_1" => "value_2" }
          expected_hash.each do |key, value|
            subject.write(key, value)
          end
          subject.close

          expect(saved_json(path)).to eq(expected_hash)
        end
      end
    end
  end

  describe "#append" do
    context "when key is already written" do
      it "appends values under a given key" do
        key = "key"
        values = %w(value_1 value_2)
        expected_hash = { key => values }
        values.each do |value|
          subject.append(key, value)
        end
        subject.close

        expect(saved_json(path)).to eq(expected_hash)
      end
    end

    context "when key is not already written" do
      it "writes correct json" do
        expected_hash = { "key" => ["value"] }
        subject.append("key", "value")
        subject.close

        expect(saved_json(path)).to eq(expected_hash)
      end
    end
  end

  describe "#set" do
    it "writes correct json" do
      expected_hash = { "key" => "value_1", "key_1" => "value_2" }
      subject.set(expected_hash)
      subject.close

      expect(saved_json(path)).to eq(expected_hash)
    end
  end

  def saved_json(filename)
    ::JSON.parse(IO.read(filename))
  end
end
