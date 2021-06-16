# frozen_string_literal: true

require "spec_helper"

RSpec.describe Gitlab::Json do
  before do
    stub_feature_flags(json_wrapper_legacy_mode: true)
  end

  describe ".parse" do
    context "legacy_mode is disabled by default" do
      it "parses an object" do
        expect(subject.parse('{ "foo": "bar" }')).to eq({ "foo" => "bar" })
      end

      it "parses an array" do
        expect(subject.parse('[{ "foo": "bar" }]')).to eq([{ "foo" => "bar" }])
      end

      it "parses a string" do
        expect(subject.parse('"foo"', legacy_mode: false)).to eq("foo")
      end

      it "parses a true bool" do
        expect(subject.parse("true", legacy_mode: false)).to be(true)
      end

      it "parses a false bool" do
        expect(subject.parse("false", legacy_mode: false)).to be(false)
      end
    end

    context "legacy_mode is enabled" do
      it "parses an object" do
        expect(subject.parse('{ "foo": "bar" }', legacy_mode: true)).to eq({ "foo" => "bar" })
      end

      it "parses an array" do
        expect(subject.parse('[{ "foo": "bar" }]', legacy_mode: true)).to eq([{ "foo" => "bar" }])
      end

      it "raises an error on a string" do
        expect { subject.parse('"foo"', legacy_mode: true) }.to raise_error(JSON::ParserError)
      end

      it "raises an error on a true bool" do
        expect { subject.parse("true", legacy_mode: true) }.to raise_error(JSON::ParserError)
      end

      it "raises an error on a false bool" do
        expect { subject.parse("false", legacy_mode: true) }.to raise_error(JSON::ParserError)
      end
    end

    context "feature flag is disabled" do
      before do
        stub_feature_flags(json_wrapper_legacy_mode: false)
      end

      it "parses an object" do
        expect(subject.parse('{ "foo": "bar" }', legacy_mode: true)).to eq({ "foo" => "bar" })
      end

      it "parses an array" do
        expect(subject.parse('[{ "foo": "bar" }]', legacy_mode: true)).to eq([{ "foo" => "bar" }])
      end

      it "parses a string" do
        expect(subject.parse('"foo"', legacy_mode: true)).to eq("foo")
      end

      it "parses a true bool" do
        expect(subject.parse("true", legacy_mode: true)).to be(true)
      end

      it "parses a false bool" do
        expect(subject.parse("false", legacy_mode: true)).to be(false)
      end
    end
  end

  describe ".parse!" do
    context "legacy_mode is disabled by default" do
      it "parses an object" do
        expect(subject.parse!('{ "foo": "bar" }')).to eq({ "foo" => "bar" })
      end

      it "parses an array" do
        expect(subject.parse!('[{ "foo": "bar" }]')).to eq([{ "foo" => "bar" }])
      end

      it "parses a string" do
        expect(subject.parse!('"foo"', legacy_mode: false)).to eq("foo")
      end

      it "parses a true bool" do
        expect(subject.parse!("true", legacy_mode: false)).to be(true)
      end

      it "parses a false bool" do
        expect(subject.parse!("false", legacy_mode: false)).to be(false)
      end
    end

    context "legacy_mode is enabled" do
      it "parses an object" do
        expect(subject.parse!('{ "foo": "bar" }', legacy_mode: true)).to eq({ "foo" => "bar" })
      end

      it "parses an array" do
        expect(subject.parse!('[{ "foo": "bar" }]', legacy_mode: true)).to eq([{ "foo" => "bar" }])
      end

      it "raises an error on a string" do
        expect { subject.parse!('"foo"', legacy_mode: true) }.to raise_error(JSON::ParserError)
      end

      it "raises an error on a true bool" do
        expect { subject.parse!("true", legacy_mode: true) }.to raise_error(JSON::ParserError)
      end

      it "raises an error on a false bool" do
        expect { subject.parse!("false", legacy_mode: true) }.to raise_error(JSON::ParserError)
      end
    end

    context "feature flag is disabled" do
      before do
        stub_feature_flags(json_wrapper_legacy_mode: false)
      end

      it "parses an object" do
        expect(subject.parse!('{ "foo": "bar" }', legacy_mode: true)).to eq({ "foo" => "bar" })
      end

      it "parses an array" do
        expect(subject.parse!('[{ "foo": "bar" }]', legacy_mode: true)).to eq([{ "foo" => "bar" }])
      end

      it "parses a string" do
        expect(subject.parse!('"foo"', legacy_mode: true)).to eq("foo")
      end

      it "parses a true bool" do
        expect(subject.parse!("true", legacy_mode: true)).to be(true)
      end

      it "parses a false bool" do
        expect(subject.parse!("false", legacy_mode: true)).to be(false)
      end
    end
  end

  describe ".dump" do
    it "dumps an object" do
      expect(subject.dump({ "foo" => "bar" })).to eq('{"foo":"bar"}')
    end

    it "dumps an array" do
      expect(subject.dump([{ "foo" => "bar" }])).to eq('[{"foo":"bar"}]')
    end

    it "dumps a string" do
      expect(subject.dump("foo")).to eq('"foo"')
    end

    it "dumps a true bool" do
      expect(subject.dump(true)).to eq("true")
    end

    it "dumps a false bool" do
      expect(subject.dump(false)).to eq("false")
    end
  end

  describe ".generate" do
    let(:obj) do
      { test: true, "foo.bar" => "baz", is_json: 1, some: [1, 2, 3] }
    end

    it "generates JSON" do
      expected_string = <<~STR.chomp
        {"test":true,"foo.bar":"baz","is_json":1,"some":[1,2,3]}
      STR

      expect(subject.generate(obj)).to eq(expected_string)
    end

    it "allows you to customise the output" do
      opts = {
        indent: "  ",
        space: " ",
        space_before: " ",
        object_nl: "\n",
        array_nl: "\n"
      }

      json = subject.generate(obj, opts)

      expected_string = <<~STR.chomp
        {
          "test" : true,
          "foo.bar" : "baz",
          "is_json" : 1,
          "some" : [
            1,
            2,
            3
          ]
        }
      STR

      expect(json).to eq(expected_string)
    end
  end

  describe ".pretty_generate" do
    let(:obj) do
      {
        test: true,
        "foo.bar" => "baz",
        is_json: 1,
        some: [1, 2, 3],
        more: { test: true },
        multi_line_empty_array: [],
        multi_line_empty_obj: {}
      }
    end

    it "generates pretty JSON" do
      expected_string = <<~STR.chomp
        {
          "test": true,
          "foo.bar": "baz",
          "is_json": 1,
          "some": [
            1,
            2,
            3
          ],
          "more": {
            "test": true
          },
          "multi_line_empty_array": [

          ],
          "multi_line_empty_obj": {
          }
        }
      STR

      expect(subject.pretty_generate(obj)).to eq(expected_string)
    end

    it "allows you to customise the output" do
      opts = {
        space_before: " "
      }

      json = subject.pretty_generate(obj, opts)

      expected_string = <<~STR.chomp
        {
          "test" : true,
          "foo.bar" : "baz",
          "is_json" : 1,
          "some" : [
            1,
            2,
            3
          ],
          "more" : {
            "test" : true
          },
          "multi_line_empty_array" : [

          ],
          "multi_line_empty_obj" : {
          }
        }
      STR

      expect(json).to eq(expected_string)
    end
  end

  context "the feature table is missing" do
    before do
      allow(Feature::FlipperFeature).to receive(:table_exists?).and_return(false)
    end

    it "skips legacy mode handling" do
      expect(Feature).not_to receive(:enabled?).with(:json_wrapper_legacy_mode, default_enabled: true)

      subject.send(:handle_legacy_mode!, {})
    end
  end

  context "the database is missing" do
    before do
      allow(Feature::FlipperFeature).to receive(:table_exists?).and_raise(PG::ConnectionBad)
    end

    it "still parses json" do
      expect(subject.parse("{}")).to eq({})
    end

    it "still generates json" do
      expect(subject.dump({})).to eq("{}")
    end
  end

  describe Gitlab::Json::GrapeFormatter do
    subject { described_class.call(obj, env) }

    let(:obj) { { test: true } }
    let(:env) { {} }
    let(:result) { "{\"test\":true}" }

    context "grape_gitlab_json flag is enabled" do
      before do
        stub_feature_flags(grape_gitlab_json: true)
      end

      it "generates JSON" do
        expect(subject).to eq(result)
      end

      it "uses Gitlab::Json" do
        expect(Gitlab::Json).to receive(:dump).with(obj)

        subject
      end
    end

    context "grape_gitlab_json flag is disabled" do
      before do
        stub_feature_flags(grape_gitlab_json: false)
      end

      it "generates JSON" do
        expect(subject).to eq(result)
      end

      it "uses Grape::Formatter::Json" do
        expect(Grape::Formatter::Json).to receive(:call).with(obj, env)

        subject
      end
    end

    context "precompiled JSON" do
      let(:obj) { Gitlab::Json::PrecompiledJson.new(result) }

      it "renders the string directly" do
        expect(subject).to eq(result)
      end

      it "calls #to_s on the object" do
        expect(obj).to receive(:to_s).once

        subject
      end

      it "doesn't run the JSON formatter" do
        expect(Gitlab::Json).not_to receive(:dump)

        subject
      end
    end
  end

  describe Gitlab::Json::PrecompiledJson do
    subject(:precompiled) { described_class.new(obj) }

    describe "#to_s" do
      subject { precompiled.to_s }

      context "obj is a string" do
        let(:obj) { "{}" }

        it "returns a string" do
          expect(subject).to eq("{}")
        end
      end

      context "obj is an array" do
        let(:obj) { ["{\"foo\": \"bar\"}", "{}"] }

        it "returns a string" do
          expect(subject).to eq("[{\"foo\": \"bar\"},{}]")
        end
      end

      context "obj is an array of un-stringables" do
        let(:obj) { [BasicObject.new] }

        it "raises an error" do
          expect { subject }.to raise_error(NoMethodError)
        end
      end

      context "obj is something else" do
        let(:obj) { {} }

        it "raises an error" do
          expect { subject }.to raise_error(described_class::UnsupportedFormatError)
        end
      end
    end
  end

  describe Gitlab::Json::LimitedEncoder do
    subject { described_class.encode(obj, limit: 10.kilobytes) }

    context 'when object size is acceptable' do
      let(:obj) { { test: true } }

      it 'returns json string' do
        is_expected.to eq("{\"test\":true}")
      end
    end

    context 'when object is too big' do
      let(:obj) { [{ test: true }] * 1000 }

      it 'raises LimitExceeded error' do
        expect { subject }.to raise_error(
          Gitlab::Json::LimitedEncoder::LimitExceeded
        )
      end
    end

    context 'when object contains ASCII-8BIT encoding' do
      let(:obj) { [{ a: "\x8F" }] * 1000 }

      it 'does not raise encoding error' do
        expect { subject }.not_to raise_error
        expect(subject).to be_a(String)
        expect(subject.size).to eq(10001)
      end
    end

    context 'when json_limited_encoder is disabled' do
      let(:obj) { [{ test: true }] * 1000 }

      it 'does not raise an error' do
        stub_feature_flags(json_limited_encoder: false)

        expect { subject }.not_to raise_error
      end
    end
  end
end
