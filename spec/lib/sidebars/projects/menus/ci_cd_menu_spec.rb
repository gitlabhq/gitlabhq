# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Projects::Menus::CiCdMenu, feature_category: :navigation do
  let(:project) { build(:project) }
  let(:user) { project.first_owner }
  let(:can_view_pipeline_editor) { true }
  let(:context) { Sidebars::Projects::Context.new(current_user: user, container: project, current_ref: 'master', can_view_pipeline_editor: can_view_pipeline_editor) }

  subject { described_class.new(context) }

  describe '#render?' do
    context 'when user cannot read builds' do
      let(:user) { nil }

      it 'returns false' do
        expect(subject.render?).to eq false
      end
    end

    context 'when user can read builds' do
      it 'returns true' do
        expect(subject.render?).to eq true
      end
    end
  end

  describe 'Menu items' do
    subject { described_class.new(context).renderable_items.index { |e| e.item_id == item_id } }

    describe 'Pipelines Editor' do
      let(:item_id) { :pipelines_editor }

      context 'when user cannot view pipeline editor' do
        let(:can_view_pipeline_editor) { false }

        it 'does not include pipeline editor menu item' do
          is_expected.to be_nil
        end
      end

      context 'when user can view pipeline editor' do
        it 'includes pipeline editor menu item' do
          is_expected.not_to be_nil
        end
      end
    end

    describe 'Artifacts' do
      let(:item_id) { :artifacts }

      it 'includes artifacts menu item' do
        is_expected.not_to be_nil
      end
    end
  end
end
