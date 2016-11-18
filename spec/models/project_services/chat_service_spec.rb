require 'spec_helper'

describe ChatService, models: true do
  describe "Associations" do
    it { is_expected.to have_many :chat_names }
  end

  describe '#valid_token?' do
    subject { described_class.new }

    it 'is false as it has no token' do
      expect(subject.valid_token?('wer')).to be_falsey
    end
  end
end
