require 'spec_helper'

describe Gitlab::Database::Count::ExactCountStrategy do
  before do
    create_list(:project, 3)
    create(:identity)
  end

  let(:models) { [Project, Identity] }

  subject { described_class.new(models).count }

  describe '#count' do
    it 'counts all models' do
      expect(models).to all(receive(:count).and_call_original)

      expect(subject).to eq({ Project => 3, Identity => 1 })
    end

    it 'returns default value if count times out' do
      allow(models.first).to receive(:count).and_raise(ActiveRecord::StatementInvalid.new(''))

      expect(subject).to eq({})
    end
  end

  describe '.enabled?' do
    it 'is enabled for PostgreSQL' do
      allow(Gitlab::Database).to receive(:postgresql?).and_return(true)

      expect(described_class.enabled?).to be_truthy
    end

    it 'is enabled for MySQL' do
      allow(Gitlab::Database).to receive(:postgresql?).and_return(false)

      expect(described_class.enabled?).to be_truthy
    end
  end
end
