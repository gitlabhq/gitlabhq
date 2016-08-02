require 'spec_helper'

describe Key, models: true do
  describe "Associations" do
    it { is_expected.to belong_to(:user) }
  end

  describe "Mass assignment" do
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
        expect(build(:key, user: user).publishable_key).to match(/#{Regexp.escape(user.name)} \(localhost\)/)
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
    it 'should add new key to authorized_file' do
      @key = build(:personal_key, id: 7)
      expect(GitlabShellWorker).to receive(:perform_async).with(:add_key, @key.shell_id, @key.key)
      @key.save
    end

    it 'should remove key from authorized_file' do
      @key = create(:personal_key)
      expect(GitlabShellWorker).to receive(:perform_async).with(:remove_key, @key.shell_id, @key.key)
      @key.destroy
    end
  end
end
