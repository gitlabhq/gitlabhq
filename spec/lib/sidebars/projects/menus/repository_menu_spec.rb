# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Projects::Menus::RepositoryMenu do
  let_it_be(:project) { create(:project, :repository) }

  let(:user) { project.first_owner }
  let(:context) { Sidebars::Projects::Context.new(current_user: user, container: project, current_ref: 'master') }

  subject { described_class.new(context) }

  describe '#render?' do
    context 'when project repository is empty' do
      it 'returns false' do
        allow(project).to receive(:empty_repo?).and_return(true)

        expect(subject.render?).to eq false
      end
    end

    context 'when project repository is not empty' do
      context 'when user can download code' do
        it 'returns true' do
          expect(subject.render?).to eq true
        end
      end

      context 'when user cannot download code' do
        let(:user) { nil }

        it 'returns false' do
          expect(subject.render?).to eq false
        end
      end
    end

    context 'for menu items' do
      subject { described_class.new(context).renderable_items.index { |e| e.item_id == item_id } }

      describe 'Contributors' do
        let_it_be(:item_id) { :contributors }

        context 'when analytics is disabled' do
          before do
            project.project_feature.update!(analytics_access_level: ProjectFeature::DISABLED)
          end

          it { is_expected.to be_nil }
        end

        context 'when analytics is enabled' do
          before do
            project.project_feature.update!(analytics_access_level: ProjectFeature::ENABLED)
          end

          it { is_expected.not_to be_nil }
        end
      end
    end
  end
end
