require 'spec_helper'

describe Labels::UpdateService do
  describe '#execute' do
    let(:project) { create(:project) }

    let(:hex_color) { '#FF0000' }
    let(:named_color) { 'red' }
    let(:upcase_color) { 'RED' }
    let(:spaced_color) { ' red ' }
    let(:unknown_color) { 'unknown' }
    let(:no_color) { '' }

    let(:expected_saved_color) { hex_color }

    before do
      @label = Labels::CreateService.new(title: 'Initial', color: '#000000').execute(project: project)
      expect(@label).to be_persisted
    end

    context 'with color in hex-code' do
      it 'updates the label' do
        label = described_class.new(params_with(hex_color)).execute(@label)

        expect(label).to be_valid
        expect(label.reload.color).to eq expected_saved_color
      end
    end

    context 'with color in allowed name' do
      it 'updates the label' do
        label = described_class.new(params_with(named_color)).execute(@label)

        expect(label).to be_valid
        expect(label.reload.color).to eq expected_saved_color
      end
    end

    context 'with color in up-case allowed name' do
      it 'updates the label' do
        label = described_class.new(params_with(upcase_color)).execute(@label)

        expect(label).to be_valid
        expect(label.reload.color).to eq expected_saved_color
      end
    end

    context 'with color surrounded by spaces' do
      it 'updates the label' do
        label = described_class.new(params_with(spaced_color)).execute(@label)

        expect(label).to be_valid
        expect(label.reload.color).to eq expected_saved_color
      end
    end

    context 'with unknown color' do
      it 'doesn\'t update the label' do
        label = described_class.new(params_with(unknown_color)).execute(@label)

        expect(label).not_to be_valid
      end
    end

    context 'with no color' do
      it 'doesn\'t update the label' do
        label = described_class.new(params_with(no_color)).execute(@label)

        expect(label).not_to be_valid
      end
    end
  end

  def params_with(color)
    {
      title: 'A Label',
      color: color
    }
  end
end
