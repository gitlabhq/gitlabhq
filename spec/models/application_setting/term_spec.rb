require 'spec_helper'

describe ApplicationSetting::Term do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:terms) }
  end

  describe '.latest' do
    it 'finds the latest terms' do
      terms = create(:term)

      expect(described_class.latest).to eq(terms)
    end
  end
end
