require 'spec_helper'

describe AvatarUploader do
  let(:user) { build(:user) }
  subject { described_class.new(user) }

  describe '#move_to_cache' do
    it 'is true' do
      expect(subject.move_to_cache).to eq(true)
    end
  end

  describe '#move_to_store' do
    it 'is true' do
      expect(subject.move_to_store).to eq(true)
    end
  end
end
