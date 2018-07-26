require 'spec_helper'

describe SiteStatistic do
  describe '.fetch' do
    context 'existing record' do
      it 'returns existing SiteStatistic model' do
        statistics = create(:site_statistics)

        expect(described_class.fetch).to be_a(described_class)
        expect(described_class.fetch).to eq(statistics)
      end
    end

    context 'non existing record' do
      it 'creates a new SiteStatistic model' do
        expect(described_class.first).to be_nil
        expect(described_class.fetch).to be_a(described_class)
      end
    end
  end

  describe '.track' do
    context 'with allowed attributes' do
      let(:statistics) { create(:site_statistics) }

      it 'increases the attribute counter' do
        expect { described_class.track('repositories_count') }.to change { statistics.reload.repositories_count }.by(1)
        expect { described_class.track('wikis_count') }.to change { statistics.reload.wikis_count }.by(1)
      end

      it 'doesnt increase the attribute counter when an exception happens during transaction' do
        expect do
          begin
            described_class.transaction do
              described_class.track('repositories_count')

              raise StandardError
            end
          rescue StandardError
            # no-op
          end
        end.not_to change { statistics.reload.repositories_count }
      end
    end

    context 'with not allowed attributes' do
      it 'returns error' do
        expect { described_class.track('something_else') }.to raise_error(ArgumentError).with_message(/Invalid attribute: \'something_else\' to \'track\' method/)
      end
    end
  end

  describe '.untrack' do
    context 'with allowed attributes' do
      let(:statistics) { create(:site_statistics) }

      it 'decreases the attribute counter' do
        expect { described_class.untrack('repositories_count') }.to change { statistics.reload.repositories_count }.by(-1)
        expect { described_class.untrack('wikis_count') }.to change { statistics.reload.wikis_count }.by(-1)
      end

      it 'doesnt decrease the attribute counter when an exception happens during transaction' do
        expect do
          begin
            described_class.transaction do
              described_class.track('repositories_count')

              raise StandardError
            end
          rescue StandardError
            # no-op
          end
        end.not_to change { described_class.fetch.repositories_count }
      end
    end

    context 'with not allowed attributes' do
      it 'returns error' do
        expect { described_class.untrack('something_else') }.to raise_error(ArgumentError).with_message(/Invalid attribute: \'something_else\' to \'untrack\' method/)
      end
    end
  end
end
