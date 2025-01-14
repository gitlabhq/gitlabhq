# frozen_string_literal: true

RSpec.shared_examples "position formatter" do
  let(:formatter) { described_class.new(attrs) }
  let(:key) { [123, 456, 789, Digest::SHA1.hexdigest(formatter.old_path), Digest::SHA1.hexdigest(formatter.new_path), 1, 2] }

  describe '#key' do
    subject { formatter.key }

    it { is_expected.to eq(key) }
  end

  describe '#complete?' do
    subject { formatter.complete? }

    context 'when there are missing key attributes' do
      it { is_expected.to be_truthy }
    end

    context 'when old_line and new_line are nil' do
      let(:attrs) { base_attrs }

      it { is_expected.to be_falsy }
    end
  end

  describe '#to_h' do
    let(:formatter_hash) do
      attrs.merge(position_type: base_attrs[:position_type] || 'text')
    end

    subject { formatter.to_h }

    it { is_expected.to eq(formatter_hash) }
  end

  describe '#==' do
    subject { formatter }

    let(:other_formatter) { described_class.new(attrs) }

    it { is_expected.to eq(other_formatter) }
  end
end
