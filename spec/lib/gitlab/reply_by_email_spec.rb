require "spec_helper"

describe Gitlab::ReplyByEmail do
  describe "self.enabled?" do
    context "when reply by email is enabled" do
      before do
        stub_reply_by_email_setting(enabled: true)
      end

      context "when the address is valid" do
        before do
          stub_reply_by_email_setting(address: "replies+%{reply_key}@example.com")
        end

        it "returns true" do
          expect(described_class.enabled?).to be_truthy
        end
      end

      context "when the address is invalid" do
        before do
          stub_reply_by_email_setting(address: "replies@example.com")
        end

        it "returns false" do
          expect(described_class.enabled?).to be_falsey
        end
      end
    end

    context "when reply by email is disabled" do
      before do
        stub_reply_by_email_setting(enabled: false)
      end

      it "returns false" do
        expect(described_class.enabled?).to be_falsey
      end
    end
  end

  describe "self.reply_key" do
    context "when enabled" do
      before do
        allow(described_class).to receive(:enabled?).and_return(true)
      end

      it "returns a random hex" do
        key = described_class.reply_key
        key2 = described_class.reply_key

        expect(key).not_to eq(key2)
      end
    end

    context "when disabled" do
      before do
        allow(described_class).to receive(:enabled?).and_return(false)
      end

      it "returns nil" do
        expect(described_class.reply_key).to be_nil
      end
    end
  end

  context "self.reply_address" do
    before do
      stub_reply_by_email_setting(address: "replies+%{reply_key}@example.com")
    end

    it "returns the address with an interpolated reply key" do
      expect(described_class.reply_address("key")).to eq("replies+key@example.com")
    end
  end

  context "self.reply_key_from_address" do
    before do
      stub_reply_by_email_setting(address: "replies+%{reply_key}@example.com")
    end

    it "returns reply key" do
      expect(described_class.reply_key_from_address("replies+key@example.com")).to eq("key")
    end
  end
end
