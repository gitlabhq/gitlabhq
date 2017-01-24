require 'spec_helper'

describe AvatarUploader do
  let(:user) { build(:user) }
  subject { described_class.new(user) }

  describe '#move_to_cache' do
    it 'is false' do
      expect(subject.move_to_cache).to eq(false)
    end
  end

  describe '#move_to_store' do
    it 'is false' do
      expect(subject.move_to_store).to eq(false)
    end
  end
end
