# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Color do
  describe ".of" do
    described_class::Constants::COLOR_NAME_TO_HEX.each do |name, value|
      it "parses #{name} to #{value}" do
        expect(described_class.of(name)).to eq(value)
      end
    end

    it 'parses hex literals as colors' do
      expect(described_class.of('#fff')).to eq(described_class.new('#fff'))
      expect(described_class.of('#fefefe')).to eq(described_class.new('#fefefe'))
    end

    it 'raises if the input is nil' do
      expect { described_class.of(nil) }.to raise_error(ArgumentError)
    end

    it 'returns an invalid color if the input is not valid' do
      expect(described_class.of('unknown color')).not_to be_valid
    end
  end

  describe '.color_for' do
    subject { described_class.color_for(value) }

    shared_examples 'deterministic' do
      it 'is deterministoc' do
        expect(subject.to_s).to eq(described_class.color_for(value).to_s)
      end
    end

    context 'when generating color for nil value' do
      let(:value) { nil }

      it { is_expected.to be_valid }

      it_behaves_like 'deterministic'
    end

    context 'when generating color for empty string value' do
      let(:value) { '' }

      it { is_expected.to be_valid }

      it_behaves_like 'deterministic'
    end

    context 'when generating color for number value' do
      let(:value) { 1 }

      it { is_expected.to be_valid }

      it_behaves_like 'deterministic'
    end

    context 'when generating color for string value' do
      let(:value) { "1" }

      it { is_expected.to be_valid }

      it_behaves_like 'deterministic'
    end
  end

  describe '#new' do
    it 'handles nil values' do
      expect(described_class.new(nil)).to eq(described_class.new(nil))
    end

    it 'strips input' do
      expect(described_class.new('  abc  ')).to eq(described_class.new('abc'))
    end
  end

  describe '#valid?' do
    described_class::Constants::COLOR_NAME_TO_HEX.each_key do |name|
      specify "#{name} is a valid color" do
        expect(described_class.of(name)).to be_valid
      end
    end

    specify '#fff is a valid color' do
      expect(described_class.new('#fff')).to be_valid
    end

    specify '#ffffff is a valid color' do
      expect(described_class.new('#ffffff')).to be_valid
    end

    specify '#ABCDEF is a valid color' do
      expect(described_class.new('#ABCDEF')).to be_valid
    end

    specify '#123456 is a valid color' do
      expect(described_class.new('#123456')).to be_valid
    end

    specify '#1234567 is not a valid color' do
      expect(described_class.new('#1234567')).not_to be_valid
    end

    specify 'fff is not a valid color' do
      expect(described_class.new('fff')).not_to be_valid
    end

    specify '#deadbeaf is not a valid color' do
      expect(described_class.new('#deadbeaf')).not_to be_valid
    end

    specify '#a1b2c3 is a valid color' do
      expect(described_class.new('#a1b2c3')).to be_valid
    end

    specify 'nil is not a valid color' do
      expect(described_class.new(nil)).not_to be_valid
    end
  end

  describe '#light?' do
    specify '#fff is light' do
      expect(described_class.new('#fff')).to be_light
    end

    specify '#c2c2c2 is light' do
      expect(described_class.new('#c2c2c2')).to be_light
    end

    specify '#868686 is dark' do
      expect(described_class.new('#868686')).not_to be_light
    end

    specify '#000 is dark' do
      expect(described_class.new('#000')).not_to be_light
    end

    specify 'invalid colors are not light' do
      expect(described_class.new('not-a-color')).not_to be_light
    end
  end

  describe '#contrast' do
    context 'with light colors' do
      it 'is dark' do
        %w[#fff #fefefe #c2c2c2].each do |hex|
          expect(described_class.new(hex)).to have_attributes(
            contrast: described_class::Constants::DARK,
            luminosity: :light
          )
        end
      end
    end

    context 'with dark colors' do
      it 'is light' do
        %w[#000 #a6a7a7].each do |hex|
          expect(described_class.new(hex)).to have_attributes(
            contrast: described_class::Constants::LIGHT,
            luminosity: :dark
          )
        end
      end
    end
  end

  describe 'as_json' do
    it 'serializes correctly' do
      expect(described_class.new('#f0f1f2').as_json).to eq('#f0f1f2')
    end
  end
end
