# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Redis::Boolean do
  subject(:redis_boolean) { described_class.new(bool) }

  let(:bool) { true }
  let(:label_section) { "#{described_class::LABEL}#{described_class::DELIMITER}" }

  describe "#to_s" do
    subject { redis_boolean.to_s }

    context "true" do
      let(:bool) { true }

      it { is_expected.to eq("#{label_section}#{described_class::TRUE_STR}") }
    end

    context "false" do
      let(:bool) { false }

      it { is_expected.to eq("#{label_section}#{described_class::FALSE_STR}") }
    end
  end

  describe ".encode" do
    subject { redis_boolean.class.encode(bool) }

    context "true" do
      let(:bool) { true }

      it { is_expected.to eq("#{label_section}#{described_class::TRUE_STR}") }
    end

    context "false" do
      let(:bool) { false }

      it { is_expected.to eq("#{label_section}#{described_class::FALSE_STR}") }
    end
  end

  describe ".decode" do
    subject { redis_boolean.class.decode(str) }

    context "valid encoded bool" do
      let(:str) { "#{label_section}#{bool_str}" }

      context "true" do
        let(:bool_str) { described_class::TRUE_STR }

        it { is_expected.to be(true) }
      end

      context "false" do
        let(:bool_str) { described_class::FALSE_STR }

        it { is_expected.to be(false) }
      end
    end

    context "partially invalid bool" do
      let(:str) { "#{label_section}whoops" }

      it "raises an error" do
        expect { subject }.to raise_error(described_class::NotAnEncodedBooleanStringError)
      end
    end

    context "invalid encoded bool" do
      let(:str) { "whoops" }

      it "raises an error" do
        expect { subject }.to raise_error(described_class::NotAnEncodedBooleanStringError)
      end
    end
  end

  describe ".true?" do
    subject { redis_boolean.class.true?(str) }

    context "valid encoded bool" do
      let(:str) { "#{label_section}#{bool_str}" }

      context "true" do
        let(:bool_str) { described_class::TRUE_STR }

        it { is_expected.to be(true) }
      end

      context "false" do
        let(:bool_str) { described_class::FALSE_STR }

        it { is_expected.to be(false) }
      end
    end

    context "partially invalid bool" do
      let(:str) { "#{label_section}whoops" }

      it "raises an error" do
        expect { subject }.to raise_error(described_class::NotAnEncodedBooleanStringError)
      end
    end

    context "invalid encoded bool" do
      let(:str) { "whoops" }

      it "raises an error" do
        expect { subject }.to raise_error(described_class::NotAnEncodedBooleanStringError)
      end
    end
  end

  describe ".false?" do
    subject { redis_boolean.class.false?(str) }

    context "valid encoded bool" do
      let(:str) { "#{label_section}#{bool_str}" }

      context "true" do
        let(:bool_str) { described_class::TRUE_STR }

        it { is_expected.to be(false) }
      end

      context "false" do
        let(:bool_str) { described_class::FALSE_STR }

        it { is_expected.to be(true) }
      end
    end

    context "partially invalid bool" do
      let(:str) { "#{label_section}whoops" }

      it "raises an error" do
        expect { subject }.to raise_error(described_class::NotAnEncodedBooleanStringError)
      end
    end

    context "invalid encoded bool" do
      let(:str) { "whoops" }

      it "raises an error" do
        expect { subject }.to raise_error(described_class::NotAnEncodedBooleanStringError)
      end
    end
  end
end
