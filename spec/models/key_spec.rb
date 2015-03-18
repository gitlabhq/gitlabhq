# == Schema Information
#
# Table name: keys
#
#  id          :integer          not null, primary key
#  user_id     :integer
#  created_at  :datetime
#  updated_at  :datetime
#  key         :text
#  title       :string(255)
#  type        :string(255)
#  fingerprint :string(255)
#

require 'spec_helper'

describe Key do
  describe "Associations" do
    it { is_expected.to belong_to(:user) }
  end

  describe "Mass assignment" do
  end

  describe "Validation" do
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:key) }
    it { is_expected.to ensure_length_of(:title).is_within(0..255) }
    it { is_expected.to ensure_length_of(:key).is_within(0..5000) }
  end

  describe "Methods" do
    it { is_expected.to respond_to :projects }
  end

  context "validation of uniqueness" do
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

    it "rejects the unfingerprintable key (contains space in middle)" do
      expect(build(:key_with_a_space_in_the_middle)).not_to be_valid
    end

    it "rejects the unfingerprintable key (not a key)" do
      expect(build(:invalid_key)).not_to be_valid
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
