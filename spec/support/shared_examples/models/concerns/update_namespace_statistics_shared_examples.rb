# frozen_string_literal: true

RSpec.shared_examples 'updates namespace statistics' do
  let(:namespace_statistics_name) { described_class.namespace_statistics_name }
  let(:statistic_attribute) { described_class.statistic_attribute }

  context 'when creating' do
    before do
      statistic_source.send("#{statistic_attribute}=", 10)
    end

    it 'schedules a statistic refresh' do
      expect(Groups::UpdateStatisticsWorker)
        .to receive(:perform_async)

      statistic_source.save!
    end
  end

  context 'when updating' do
    before do
      statistic_source.save!

      expect(statistic_source).to be_persisted
    end

    context 'when the statistic attribute has not changed' do
      it 'does not schedule a statistic refresh' do
        expect(Groups::UpdateStatisticsWorker)
          .not_to receive(:perform_async)

        statistic_source.update!(file_name: 'new-file-name.txt')
      end
    end

    context 'when the statistic attribute has changed' do
      it 'schedules a statistic refresh' do
        expect(Groups::UpdateStatisticsWorker)
          .to receive(:perform_async)

        statistic_source.update!(statistic_attribute => 20)
      end
    end
  end

  context 'when deleting' do
    it 'schedules a statistic refresh' do
      expect(Groups::UpdateStatisticsWorker)
        .to receive(:perform_async)

      statistic_source.destroy!
    end
  end
end
