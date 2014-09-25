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
    it { should belong_to(:user) }
  end

  describe "Mass assignment" do
  end

  describe "Validation" do
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:key) }
    it { should ensure_length_of(:title).is_within(0..255) }
    it { should ensure_length_of(:key).is_within(0..5000) }
  end

  describe "Methods" do
    it { should respond_to :projects }
  end

  context "validation of uniqueness" do
    let(:user) { create(:user) }

    it "accepts the key once" do
      build(:key, user: user).should be_valid
    end

    it "does not accept the exact same key twice" do
      create(:key, user: user)
      build(:key, user: user).should_not be_valid
    end

    it "does not accept a duplicate key with a different comment" do
      create(:key, user: user)
      duplicate = build(:key, user: user)
      duplicate.key << ' extra comment'
      duplicate.should_not be_valid
    end
  end

  context "validate it is a fingerprintable key" do
    it "accepts the fingerprintable key" do
      build(:key).should be_valid
    end

    it "rejects the unfingerprintable key (contains space in middle)" do
      build(:key_with_a_space_in_the_middle).should_not be_valid
    end

    it "rejects the unfingerprintable key (not a key)" do
      build(:invalid_key).should_not be_valid
    end
  end

  context 'callbacks' do
    it 'should add new key to authorized_file' do
      @key = build(:personal_key, id: 7)
      GitlabShellWorker.should_receive(:perform_async).with(:add_key, @key.shell_id, @key.key)
      @key.save
    end

    it 'should remove key from authorized_file' do
      @key = create(:personal_key)
      GitlabShellWorker.should_receive(:perform_async).with(:remove_key, @key.shell_id, @key.key)
      @key.destroy
    end
  end
end
