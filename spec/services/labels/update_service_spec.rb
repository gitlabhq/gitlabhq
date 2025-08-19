# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Labels::UpdateService, feature_category: :team_planning do
  describe '#execute' do
    let(:project) { create(:project) }

    let(:hex_color) { '#FF0000' }
    let(:named_color) { 'red' }
    let(:upcase_color) { 'RED' }
    let(:spaced_color) { ' red ' }
    let(:unknown_color) { 'unknown' }
    let(:no_color) { '' }

    let(:expected_saved_color) { ::Gitlab::Color.of(hex_color) }

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

    describe 'lock_on_merge' do
      let_it_be(:params) { { lock_on_merge: true } }

      context 'when feature flag is disabled' do
        before do
          stub_feature_flags(enforce_locked_labels_on_merge: false)
        end

        it 'does not allow setting lock_on_merge' do
          label = described_class.new(params).execute(@label)

          expect(label.reload.lock_on_merge).to be_falsey

          template_label = create(:admin_label, title: 'Initial')
          label = described_class.new(params).execute(template_label)

          expect(label.reload.lock_on_merge).to be_falsey
        end
      end

      context 'when feature flag is enabled' do
        it 'allows setting lock_on_merge' do
          label = described_class.new(params).execute(@label)

          expect(label.reload.lock_on_merge).to be_truthy
        end

        it 'does not allow lock_on_merge to be unset' do
          label_locked = Labels::CreateService.new(title: 'Initial', lock_on_merge: true).execute(project: project)
          label = described_class.new(title: 'test', lock_on_merge: false).execute(label_locked)

          expect(label.reload.lock_on_merge).to be_truthy
          expect(label.reload.title).to eq 'test'
        end

        it 'does not allow setting lock_on_merge for templates' do
          template_label = create(:admin_label, title: 'Initial')
          label = described_class.new(params).execute(template_label)

          expect(label.reload.lock_on_merge).to be_falsey
        end
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
