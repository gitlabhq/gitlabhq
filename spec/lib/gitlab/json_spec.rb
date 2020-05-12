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

      # These tests will change expectations when the gem is upgraded

      it "raises an error on a string" do
        expect { subject.parse('"foo"') }.to raise_error(JSON::ParserError)
      end

      it "raises an error on a true bool" do
        expect { subject.parse("true") }.to raise_error(JSON::ParserError)
      end

      it "raises an error on a false bool" do
        expect { subject.parse("false") }.to raise_error(JSON::ParserError)
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
  end

  describe ".parse!" do
    context "legacy_mode is disabled by default" do
      it "parses an object" do
        expect(subject.parse!('{ "foo": "bar" }')).to eq({ "foo" => "bar" })
      end

      it "parses an array" do
        expect(subject.parse!('[{ "foo": "bar" }]')).to eq([{ "foo" => "bar" }])
      end

      # These tests will change expectations when the gem is upgraded

      it "raises an error on a string" do
        expect { subject.parse!('"foo"') }.to raise_error(JSON::ParserError)
      end

      it "raises an error on a true bool" do
        expect { subject.parse!("true") }.to raise_error(JSON::ParserError)
      end

      it "raises an error on a false bool" do
        expect { subject.parse!("false") }.to raise_error(JSON::ParserError)
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
    it "delegates to the adapter" do
      args = [{ foo: "bar" }]

      expect(JSON).to receive(:generate).with(*args)

      subject.generate(*args)
    end
  end

  describe ".pretty_generate" do
    it "delegates to the adapter" do
      args = [{ foo: "bar" }]

      expect(JSON).to receive(:pretty_generate).with(*args)

      subject.pretty_generate(*args)
    end
  end
end
