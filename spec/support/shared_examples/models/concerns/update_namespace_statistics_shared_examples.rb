# frozen_string_literal: true

RSpec.shared_examples 'updates namespace statistics' do
  let(:namespace_statistics_name) { described_class.namespace_statistics_name }
  let(:statistic_attribute) { described_class.statistic_attribute }
  let(:non_statistic_attribute) { :file_name }

  shared_examples 'skipping statistics update if namespace is nil' do
    context 'when the namespace is nil' do
      before do
        allow(statistic_source).to receive(:namespace).and_return(nil)
      end

      it 'does not schedule a statistic refresh' do
        expect(::Groups::UpdateStatisticsWorker).not_to receive(:perform_async)

        subject
      end
    end
  end

  context 'when creating' do
    subject { statistic_source.save! }

    before do
      statistic_source.send(:"#{statistic_attribute}=", 10)
      allow(::Groups::UpdateStatisticsWorker).to receive(:perform_async)
    end

    it 'schedules a statistic refresh' do
      subject

      expect(::Groups::UpdateStatisticsWorker)
        .to have_received(:perform_async).with(statistic_source.namespace.id, [namespace_statistics_name.to_s])
    end

    it_behaves_like 'skipping statistics update if namespace is nil'
  end

  context 'when updating' do
    before do
      statistic_source.save!
    end

    context 'when the statistic attribute has not changed' do
      it 'does not schedule a statistic refresh' do
        expect(Groups::UpdateStatisticsWorker)
          .not_to receive(:perform_async)

        statistic_source.update!(non_statistic_attribute => 'new-file-name.txt')
      end
    end

    context 'when the statistic attribute has changed' do
      subject { statistic_source.update!(statistic_attribute => 20) }

      it 'schedules a statistic refresh' do
        expect(Groups::UpdateStatisticsWorker)
          .to receive(:perform_async)

        subject
      end

      it_behaves_like 'skipping statistics update if namespace is nil'
    end
  end

  context 'when deleting' do
    subject { statistic_source.destroy! }

    it 'schedules a statistic refresh' do
      statistic_source.save!

      expect(Groups::UpdateStatisticsWorker)
        .to receive(:perform_async)

      subject
    end

    it_behaves_like 'skipping statistics update if namespace is nil'
  end
end
