require 'spec_helper'

describe AwardEmoji do
  describe '.urls' do
    subject { AwardEmoji.urls }

    it { is_expected.to be_an_instance_of(Array) }
    it { is_expected.to_not be_empty }

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
      undefined_categories = AwardEmoji.emoji_by_category.keys - AwardEmoji::CATEGORIES.keys
      expect(undefined_categories).to be_empty
    end
  end
end
