require 'spec_helper'

describe Gitlab::Feature do
  Gitlab::Feature::FEATURES.each do |feature|
    describe ".#{feature}_enabled?" do
      it 'returns a boolean' do
        expect(described_class.__send__("#{feature}_enabled?")).
          to be_in([true, false])
      end
    end
  end

  describe '.feature_enabled?' do
    it 'returns true when the column does not exist' do
      settings = double(:settings)

      expect(described_class).to receive(:current_application_settings).
        and_return(settings)

      expect(described_class.feature_enabled?(:foo)).to eq(true)
    end
  end

  describe '.features_with_columns' do
    it 'returns a Hash mapping feature names to their columns' do
      map = described_class.features_with_columns

      expect(map).to be_an_instance_of(Hash)
      expect(map[:creating_notes]).to eq(:enable_creating_notes)
    end
  end

  describe '.column_names' do
    it 'returns an Array of column names' do
      names = described_class.column_names

      expect(names).to be_an_instance_of(Array)
      expect(names).to include(:enable_creating_notes)
    end
  end

  describe '.column_name' do
    it 'returns the column name of a feature flag' do
      expect(described_class.column_name(:foo)).to eq(:enable_foo)
    end
  end
end
