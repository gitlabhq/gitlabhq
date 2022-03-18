# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WebIdeButtonHelper do
  describe '#show_pipeline_editor_button?' do
    subject(:result) { helper.show_pipeline_editor_button?(project, path) }

    let_it_be(:project) { build(:project) }

    context 'when can view pipeline editor' do
      before do
        allow(helper).to receive(:can_view_pipeline_editor?).and_return(true)
      end

      context 'when path is ci config path' do
        let(:path) { project.ci_config_path_or_default }

        it 'returns true' do
          expect(result).to eq(true)
        end
      end

      context 'when path is not config path' do
        let(:path) { '/' }

        it 'returns false' do
          expect(result).to eq(false)
        end
      end
    end

    context 'when can not view pipeline editor' do
      before do
        allow(helper).to receive(:can_view_pipeline_editor?).and_return(false)
      end

      let(:path) { project.ci_config_path_or_default }

      it 'returns false' do
        expect(result).to eq(false)
      end
    end
  end
end
