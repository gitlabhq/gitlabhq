# frozen_string_literal: true

RSpec.shared_examples 'worker with data consistency' do |worker_class, data_consistency: :always, feature_flag: nil|
  describe '.get_data_consistency_feature_flag_enabled?' do
    it 'returns true' do
      expect(worker_class.get_data_consistency_feature_flag_enabled?).to be(true)
    end

    if feature_flag
      context "when feature flag :#{feature_flag} is disabled" do
        before do
          stub_feature_flags(feature_flag => false)
        end

        it 'returns false' do
          expect(worker_class.get_data_consistency_feature_flag_enabled?).to be(false)
        end
      end
    end
  end

  describe '.get_data_consistency_per_database' do
    it 'returns correct data consistency' do
      expect(worker_class.get_data_consistency_per_database.values.uniq).to eq([data_consistency])
    end
  end
end
