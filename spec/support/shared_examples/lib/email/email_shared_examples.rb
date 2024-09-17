# frozen_string_literal: true

# Set the particular setting as a key-value pair
# Setting method is different depending on klass and must be defined in the calling spec
def stub_email_setting(key_value_pairs)
  case setting_name
  when :incoming_email
    stub_incoming_email_setting(key_value_pairs)
  when :service_desk_email
    stub_service_desk_email_setting(key_value_pairs)
  end
end

RSpec.shared_examples_for 'enabled? method for email' do
  using RSpec::Parameterized::TableSyntax

  subject { described_class.enabled? }

  where(:value, :address, :result) do
    false | nil | false
    false | 'replies+%{key}@example.com' | false
    true  | nil | false
    true  | 'replies+%{key}@example.com' | true
  end

  with_them do
    before do
      stub_email_setting(enabled: value)
      stub_email_setting(address: address)
    end

    it { is_expected.to eq result }
  end
end

RSpec.shared_examples_for 'supports_wildcard? method for email' do
  subject { described_class.supports_wildcard? }

  before do
    stub_incoming_email_setting(address: value)
  end

  context 'when address contains the wildcard placeholder' do
    let(:value) { 'replies+%{key}@example.com' }

    it 'confirms that wildcard is supported' do
      expect(subject).to be_truthy
    end
  end

  context "when address doesn't contain the wildcard placeholder" do
    let(:value) { 'replies@example.com' }

    it 'returns that wildcard is not supported' do
      expect(subject).to be_falsey
    end
  end

  context 'when address is nil' do
    let(:value) { nil }

    it 'returns that wildcard is not supported' do
      expect(subject).to be_falsey
    end
  end
end

RSpec.shared_examples_for 'unsubscribe_address method for email' do
  before do
    stub_incoming_email_setting(address: 'replies+%{key}@example.com')
  end

  it 'returns the address with interpolated reply key and unsubscribe suffix' do
    expect(described_class.unsubscribe_address('key'))
      .to eq("replies+key#{Gitlab::Email::Common::UNSUBSCRIBE_SUFFIX}@example.com")
  end
end

RSpec.shared_examples_for 'key_from_fallback_message_id method for email' do
  it 'returns reply key' do
    expect(described_class.key_from_fallback_message_id('reply-key@localhost')).to eq('key')
  end
end

RSpec.shared_examples_for 'supports_issue_creation? method for email' do
  using RSpec::Parameterized::TableSyntax

  subject { described_class.supports_issue_creation? }

  where(:enabled_value, :supports_wildcard_value, :result) do
    false | false | false
    false | true  | false
    true  | false | false
    true  | true  | true
  end

  with_them do
    before do
      allow(described_class).to receive(:enabled?).and_return(enabled_value)
      allow(described_class).to receive(:supports_wildcard?).and_return(supports_wildcard_value)
    end

    it { is_expected.to eq result }
  end
end

RSpec.shared_examples_for 'reply_address method for email' do
  before do
    stub_incoming_email_setting(address: "replies+%{key}@example.com")
  end

  it "returns the address with an interpolated reply key" do
    expect(described_class.reply_address("key")).to eq("replies+key@example.com")
  end
end

RSpec.shared_examples_for 'scan_fallback_references method for email' do
  let(:references) do
    '<issue_1@localhost> ' \
    '<reply-59d8df8370b7e95c5a49fbf86aeb2c93@localhost>' \
    ',<exchange@microsoft.com>'
  end

  it 'returns reply key' do
    expect(described_class.scan_fallback_references(references))
      .to eq(%w[issue_1@localhost
        reply-59d8df8370b7e95c5a49fbf86aeb2c93@localhost
        exchange@microsoft.com])
  end
end

RSpec.shared_examples_for 'common email methods' do
  it_behaves_like 'enabled? method for email'
  it_behaves_like 'supports_wildcard? method for email'
  it_behaves_like 'key_from_fallback_message_id method for email'
  it_behaves_like 'supports_issue_creation? method for email'
  it_behaves_like 'reply_address method for email'
  it_behaves_like 'unsubscribe_address method for email'
  it_behaves_like 'scan_fallback_references method for email'
end
