require 'spec_helper'

describe Gitlab::AwardEmoji do
  describe '.urls' do
    subject { Gitlab::AwardEmoji.urls }

    it { is_expected.to be_an_instance_of(Array) }
    it { is_expected.not_to be_empty }

    context 'every Hash in the Array' do
      it 'has the correct keys and values' do
        subject.each do |hash|
          expect(hash[:name]).to be_an_instance_of(String)
          expect(hash[:path]).to be_an_instance_of(String)
        end
      end
    end
  end

  describe '.emoji_by_category' do
    it "only contains known categories" do
      undefined_categories = Gitlab::AwardEmoji.emoji_by_category.keys - Gitlab::AwardEmoji::CATEGORIES.keys
      expect(undefined_categories).to be_empty
    end
  end
end
