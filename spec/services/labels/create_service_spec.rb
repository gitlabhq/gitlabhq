# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Labels::CreateService, feature_category: :team_planning do
  describe '#execute' do
    let(:project) { create(:project) }
    let(:group)   { create(:group) }

    let(:hex_color) { '#FF0000' }
    let(:named_color) { 'red' }
    let(:upcase_color) { 'RED' }
    let(:spaced_color) { ' red ' }
    let(:unknown_color) { 'unknown' }
    let(:no_color) { '' }

    let(:expected_saved_color) { ::Gitlab::Color.of(hex_color) }

    context 'in a project' do
      context 'with color in hex-code' do
        it 'creates a label' do
          label = described_class.new(params_with(hex_color)).execute(project: project)

          expect(label).to be_persisted
          expect(label.color).to eq expected_saved_color
        end
      end

      context 'with color in allowed name' do
        it 'creates a label' do
          label = described_class.new(params_with(named_color)).execute(project: project)

          expect(label).to be_persisted
          expect(label.color).to eq expected_saved_color
        end
      end

      context 'with color in up-case allowed name' do
        it 'creates a label' do
          label = described_class.new(params_with(upcase_color)).execute(project: project)

          expect(label).to be_persisted
          expect(label.color).to eq expected_saved_color
        end
      end

      context 'with color surrounded by spaces' do
        it 'creates a label' do
          label = described_class.new(params_with(spaced_color)).execute(project: project)
          expect(label).to be_persisted
          expect(label.color).to eq expected_saved_color
        end
      end

      context 'with unknown color' do
        it 'doesn\'t create a label' do
          label = described_class.new(params_with(unknown_color)).execute(project: project)

          expect(label).not_to be_persisted
        end
      end

      context 'with no color' do
        it 'doesn\'t create a label' do
          label = described_class.new(params_with(no_color)).execute(project: project)

          expect(label).not_to be_persisted
        end
      end
    end

    context 'in a group' do
      context 'with color in hex-code' do
        it 'creates a label' do
          label = described_class.new(params_with(hex_color)).execute(group: group)

          expect(label).to be_persisted
          expect(label.color).to eq expected_saved_color
        end
      end

      context 'with color in allowed name' do
        it 'creates a label' do
          label = described_class.new(params_with(named_color)).execute(group: group)

          expect(label).to be_persisted
          expect(label.color).to eq expected_saved_color
        end
      end

      context 'with color in up-case allowed name' do
        it 'creates a label' do
          label = described_class.new(params_with(upcase_color)).execute(group: group)

          expect(label).to be_persisted
          expect(label.color).to eq expected_saved_color
        end
      end

      context 'with color surrounded by spaces' do
        it 'creates a label' do
          label = described_class.new(params_with(spaced_color)).execute(group: group)

          expect(label).to be_persisted
          expect(label.color).to eq expected_saved_color
        end
      end

      context 'with unknown color' do
        it 'doesn\'t create a label' do
          label = described_class.new(params_with(unknown_color)).execute(group: group)

          expect(label).not_to be_persisted
        end
      end

      context 'with no color' do
        it 'doesn\'t create a label' do
          label = described_class.new(params_with(no_color)).execute(group: group)

          expect(label).not_to be_persisted
        end
      end
    end

    context 'in admin area' do
      context 'with color in hex-code' do
        it 'creates a label' do
          label = described_class.new(params_with(hex_color)).execute(template: true)

          expect(label).to be_persisted
          expect(label.color).to eq expected_saved_color
        end
      end

      context 'with color in allowed name' do
        it 'creates a label' do
          label = described_class.new(params_with(named_color)).execute(template: true)

          expect(label).to be_persisted
          expect(label.color).to eq expected_saved_color
        end
      end

      context 'with color in up-case allowed name' do
        it 'creates a label' do
          label = described_class.new(params_with(upcase_color)).execute(template: true)

          expect(label).to be_persisted
          expect(label.color).to eq expected_saved_color
        end
      end

      context 'with color surrounded by spaces' do
        it 'creates a label' do
          label = described_class.new(params_with(spaced_color)).execute(template: true)

          expect(label).to be_persisted
          expect(label.color).to eq expected_saved_color
        end
      end

      context 'with unknown color' do
        it 'doesn\'t create a label' do
          label = described_class.new(params_with(unknown_color)).execute(template: true)

          expect(label).not_to be_persisted
        end
      end

      context 'with no color' do
        it 'doesn\'t create a label' do
          label = described_class.new(params_with(no_color)).execute(template: true)

          expect(label).not_to be_persisted
        end
      end
    end

    describe 'lock_on_merge' do
      let_it_be(:params) { { title: 'Locked label', lock_on_merge: true } }

      context 'when feature flag is disabled' do
        before do
          stub_feature_flags(enforce_locked_labels_on_merge: false)
        end

        it 'does not allow setting lock_on_merge' do
          label = described_class.new(params).execute(project: project)
          label2 = described_class.new(params).execute(group: group)
          label3 = described_class.new(params).execute(template: true)

          expect(label.lock_on_merge).to be_falsey
          expect(label2.lock_on_merge).to be_falsey
          expect(label3).not_to be_persisted
        end
      end

      context 'when feature flag is enabled' do
        it 'allows setting lock_on_merge' do
          label = described_class.new(params).execute(project: project)
          label2 = described_class.new(params).execute(group: group)

          expect(label.lock_on_merge).to be_truthy
          expect(label2.lock_on_merge).to be_truthy
        end

        it 'does not alow setting lock_on_merge for templates' do
          label = described_class.new(params).execute(template: true)

          expect(label).not_to be_persisted
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
