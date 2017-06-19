require 'spec_helper'

describe HistoricalDataWorker do
  subject { described_class.new }

  describe '#perform' do
    context 'with a trial license' do
      before do
        FactoryGirl.create(:trial_license)
      end

      it 'does not track historical data' do
        expect(HistoricalData).not_to receive(:track!)

        subject.perform
      end
    end

    context 'with a non trial license' do
      before do
        FactoryGirl.create(:license)
      end

      it 'tracks historical data' do
        expect(HistoricalData).to receive(:track!)

        subject.perform
      end
    end

    context 'with a Geo secondary node' do
      it 'does not track historical data' do
        allow(Gitlab::Geo).to receive(:secondary?).and_return(true)

        expect(HistoricalData).not_to receive(:track!)

        subject.perform
      end
    end

    context 'when there is not a license key' do
      it 'does not track historical data' do
        License.destroy_all

        expect(HistoricalData).not_to receive(:track!)

        subject.perform
      end
    end
  end
end
