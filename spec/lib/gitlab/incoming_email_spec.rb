require "spec_helper"

describe Gitlab::IncomingEmail do
  describe "self.enabled?" do
    context "when reply by email is enabled" do
      before do
        stub_incoming_email_setting(enabled: true)
      end

      it 'returns true' do
        expect(described_class.enabled?).to be_truthy
      end
    end

    context "when reply by email is disabled" do
      before do
        stub_incoming_email_setting(enabled: false)
      end

      it "returns false" do
        expect(described_class.enabled?).to be_falsey
      end
    end
  end

  describe 'self.supports_wildcard?' do
    context 'address contains the wildard placeholder' do
      before do
        stub_incoming_email_setting(address: 'replies+%{key}@example.com')
      end

      it 'confirms that wildcard is supported' do
        expect(described_class.supports_wildcard?).to be_truthy
      end
    end

    context "address doesn't contain the wildcard placeholder" do
      before do
        stub_incoming_email_setting(address: 'replies@example.com')
      end

      it 'returns that wildcard is not supported' do
        expect(described_class.supports_wildcard?).to be_falsey
      end
    end

    context 'address is not set' do
      before do
        stub_incoming_email_setting(address: nil)
      end

      it 'returns that wildard is not supported' do
        expect(described_class.supports_wildcard?).to be_falsey
      end
    end
  end

  context 'self.unsubscribe_address' do
    before do
      stub_incoming_email_setting(address: 'replies+%{key}@example.com')
    end

    it 'returns the address with interpolated reply key and unsubscribe suffix' do
      expect(described_class.unsubscribe_address('key')).to eq('replies+key+unsubscribe@example.com')
    end
  end

  context "self.reply_address" do
    before do
      stub_incoming_email_setting(address: "replies+%{key}@example.com")
    end

    it "returns the address with an interpolated reply key" do
      expect(described_class.reply_address("key")).to eq("replies+key@example.com")
    end
  end

  context "self.key_from_address" do
    before do
      stub_incoming_email_setting(address: "replies+%{key}@example.com")
    end

    it "returns reply key" do
      expect(described_class.key_from_address("replies+key@example.com")).to eq("key")
    end

    context "on GitLab.com" do
      before do
        allow(Gitlab).to receive(:com?).and_return(true)
      end

      it "returns the reply key when using @gitlab.com" do
        expect(described_class.key_from_address("incoming+key@gitlab.com")).to eq("key")
      end

      it "returns the reply key when using @incoming.gitlab.com" do
        expect(described_class.key_from_address("incoming+key@incoming.gitlab.com")).to eq("key")
      end

      it "does not match other addresses" do
        expect(described_class.key_from_address("fooincoming+key@incoming.gitlab.com")).to be_nil
        expect(described_class.key_from_address("incoming+key@incoming.gitlab.com.someotherdomain.com")).to be_nil
      end
    end
  end

  context 'self.key_from_fallback_message_id' do
    it 'returns reply key' do
      expect(described_class.key_from_fallback_message_id('reply-key@localhost')).to eq('key')
    end
  end

  context 'self.scan_fallback_references' do
    let(:references) do
      '<issue_1@localhost>' +
        ' <reply-59d8df8370b7e95c5a49fbf86aeb2c93@localhost>' +
        ',<exchange@microsoft.com>'
    end

    it 'returns reply key' do
      expect(described_class.scan_fallback_references(references))
        .to eq(%w[issue_1@localhost
                  reply-59d8df8370b7e95c5a49fbf86aeb2c93@localhost
                  exchange@microsoft.com])
    end
  end
end
