# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ImportExport::Json::LegacyWriter do
  let(:path) { "#{Dir.tmpdir}/legacy_writer_spec/test.json" }

  subject do
    described_class.new(path, allowed_path: "project")
  end

  after do
    FileUtils.rm_rf(path)
  end

  describe "#write_attributes" do
    it "writes correct json" do
      expected_hash = { "key" => "value_1", "key_1" => "value_2" }
      subject.write_attributes("project", expected_hash)

      expect(subject_json).to eq(expected_hash)
    end

    context 'when invalid path is used' do
      it 'raises an exception' do
        expect { subject.write_attributes("invalid", { "key" => "value" }) }
          .to raise_error(ArgumentError)
      end
    end
  end

  describe "#write_relation" do
    context "when key is already written" do
      it "raises exception" do
        subject.write_relation("project", "key", "old value")

        expect { subject.write_relation("project", "key", "new value") }
          .to raise_exception("key 'key' already written")
      end
    end

    context "when key is not already written" do
      context "when multiple key value pairs are stored" do
        it "writes correct json" do
          expected_hash = { "key" => "value_1", "key_1" => "value_2" }
          expected_hash.each do |key, value|
            subject.write_relation("project", key, value)
          end

          expect(subject_json).to eq(expected_hash)
        end
      end
    end

    context 'when invalid path is used' do
      it 'raises an exception' do
        expect { subject.write_relation("invalid", "key", "value") }
          .to raise_error(ArgumentError)
      end
    end
  end

  describe "#write_relation_array" do
    context 'when array is used' do
      it 'writes correct json' do
        subject.write_relation_array("project", "key", ["value"])

        expect(subject_json).to eq({ "key" => ["value"] })
      end
    end

    context 'when enumerable is used' do
      it 'writes correct json' do
        values = %w(value1 value2)

        enumerator = Enumerator.new do |items|
          values.each { |value| items << value }
        end

        subject.write_relation_array("project", "key", enumerator)

        expect(subject_json).to eq({ "key" => values })
      end
    end

    context "when key is already written" do
      it "raises an exception" do
        subject.write_relation_array("project", "key", %w(old_value))

        expect { subject.write_relation_array("project", "key", %w(new_value)) }
          .to raise_error(ArgumentError)
      end
    end
  end

  def subject_json
    subject.close

    ::JSON.parse(IO.read(subject.path))
  end
end
