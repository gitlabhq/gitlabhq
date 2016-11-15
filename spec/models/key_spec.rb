require 'spec_helper'

describe Key, models: true do
  describe "Associations" do
    it { is_expected.to belong_to(:user) }
  end

  describe "Validation" do
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:key) }
    it { is_expected.to validate_length_of(:title).is_within(0..255) }
    it { is_expected.to validate_length_of(:key).is_within(0..5000) }
  end

  describe "Methods" do
    let(:user) { create(:user) }
    it { is_expected.to respond_to :projects }
    it { is_expected.to respond_to :publishable_key }

    describe "#publishable_keys" do
      it 'replaces SSH key comment with simple identifier of username + hostname' do
        expect(build(:key, user: user).publishable_key).to include("#{user.name} (localhost)")
      end
    end
  end

  context "validation of uniqueness (based on fingerprint uniqueness)" do
    let(:user) { create(:user) }

    it "accepts the key once" do
      expect(build(:key, user: user)).to be_valid
    end

    it "does not accept the exact same key twice" do
      create(:key, user: user)
      expect(build(:key, user: user)).not_to be_valid
    end

    it "does not accept a duplicate key with a different comment" do
      create(:key, user: user)
      duplicate = build(:key, user: user)
      duplicate.key << ' extra comment'
      expect(duplicate).not_to be_valid
    end
  end

  context "validate it is a fingerprintable key" do
    it "accepts the fingerprintable key" do
      expect(build(:key)).to be_valid
    end

    it 'rejects an unfingerprintable key that contains a space' do
      key = build(:key)

      # Not always the middle, but close enough
      key.key = key.key[0..100] + ' ' + key.key[101..-1]

      expect(key).not_to be_valid
    end

    it 'rejects the unfingerprintable key (not a key)' do
      expect(build(:key, key: 'ssh-rsa an-invalid-key==')).not_to be_valid
    end

    it 'rejects the multiple line key' do
      key = build(:key)
      key.key.tr!(' ', "\n")
      expect(key).not_to be_valid
    end
  end

  context 'callbacks' do
    it 'adds new key to authorized_file' do
      @key = build(:personal_key, id: 7)
      expect(GitlabShellWorker).to receive(:perform_async).with(:add_key, @key.shell_id, @key.key)
      @key.save
    end

    it 'removes key from authorized_file' do
      @key = create(:personal_key)
      expect(GitlabShellWorker).to receive(:perform_async).with(:remove_key, @key.shell_id, @key.key)
      @key.destroy
    end
  end

  describe '#key=' do
    let(:valid_key) do
      "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAIEAiPWx6WM4lhHNedGfBpPJNPpZ7yKu+dnn1SJejgt4596k6YjzGGphH2TUxwKzxcKDKKezwkpfnxPkSMkuEspGRt/aZZ9wa++Oi7Qkr8prgHc4soW6NUlfDzpvZK2H5E7eQaSeP3SAwGmQKUFHCddNaP0L+hM7zhFNzjFvpaMgJw0= dummy@gitlab.com"
    end

    it 'strips white spaces' do
      expect(described_class.new(key: " #{valid_key} ").key).to eq(valid_key)
    end
  end
end
