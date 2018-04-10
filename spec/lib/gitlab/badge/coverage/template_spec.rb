require 'spec_helper'

describe Gitlab::Badge::Coverage::Template do
  let(:badge) { double(entity: 'coverage', status: 90.00) }
  let(:template) { described_class.new(badge) }

  describe '#key_text' do
    it 'is always says coverage' do
      expect(template.key_text).to eq 'coverage'
    end
  end

  describe '#value_text' do
    context 'when coverage is known' do
      it 'returns coverage percentage' do
        expect(template.value_text).to eq '90.00%'
      end
    end

    context 'when coverage is known to many digits' do
      before do
        allow(badge).to receive(:status).and_return(92.349)
      end

      it 'returns rounded coverage percentage' do
        expect(template.value_text).to eq '92.35%'
      end
    end

    context 'when coverage is unknown' do
      before do
        allow(badge).to receive(:status).and_return(nil)
      end

      it 'returns string that says coverage is unknown' do
        expect(template.value_text).to eq 'unknown'
      end
    end
  end

  describe '#key_width' do
    it 'has a fixed key width' do
      expect(template.key_width).to eq 62
    end
  end

  describe '#value_width' do
    context 'when coverage is known' do
      it 'is narrower when coverage is known' do
        expect(template.value_width).to eq 54
      end
    end

    context 'when coverage is unknown' do
      before do
        allow(badge).to receive(:status).and_return(nil)
      end

      it 'is wider when coverage is unknown to fit text' do
        expect(template.value_width).to eq 58
      end
    end
  end

  describe '#key_color' do
    it 'always has the same color' do
      expect(template.key_color).to eq '#555'
    end
  end

  describe '#value_color' do
    context 'when coverage is good' do
      before do
        allow(badge).to receive(:status).and_return(98)
      end

      it 'is green' do
        expect(template.value_color).to eq '#4c1'
      end
    end

    context 'when coverage is acceptable' do
      before do
        allow(badge).to receive(:status).and_return(90)
      end

      it 'is green-orange' do
        expect(template.value_color).to eq '#a3c51c'
      end
    end

    context 'when coverage is medium' do
      before do
        allow(badge).to receive(:status).and_return(75)
      end

      it 'is orange-yellow' do
        expect(template.value_color).to eq '#dfb317'
      end
    end

    context 'when coverage is low' do
      before do
        allow(badge).to receive(:status).and_return(50)
      end

      it 'is red' do
        expect(template.value_color).to eq '#e05d44'
      end
    end

    context 'when coverage is unknown' do
      before do
        allow(badge).to receive(:status).and_return(nil)
      end

      it 'is grey' do
        expect(template.value_color).to eq '#9f9f9f'
      end
    end
  end

  describe '#width' do
    context 'when coverage is known' do
      it 'returns the key width plus value width' do
        expect(template.width).to eq 116
      end
    end

    context 'when coverage is unknown' do
      before do
        allow(badge).to receive(:status).and_return(nil)
      end

      it 'returns key width plus wider value width' do
        expect(template.width).to eq 120
      end
    end
  end
end
