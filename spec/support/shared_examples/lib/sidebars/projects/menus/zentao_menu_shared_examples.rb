# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples 'ZenTao menu with CE version' do
  let(:project) { create(:project, has_external_issue_tracker: true) }
  let(:user) { project.first_owner }
  let(:context) { Sidebars::Projects::Context.new(current_user: user, container: project) }
  let(:zentao_integration) { create(:zentao_integration, project: project) }

  subject { described_class.new(context) }

  describe '#render?' do
    context 'when issues integration is disabled' do
      before do
        zentao_integration.update!(active: false)
      end

      it 'returns false' do
        expect(subject.render?).to eq false
      end
    end

    context 'when issues integration is enabled' do
      before do
        zentao_integration.update!(active: true)
      end

      it 'returns true' do
        expect(subject.render?).to eq true
      end

      it 'renders menu link' do
        expect(subject.link).to eq zentao_integration.url
      end

      it 'contains only open ZenTao item' do
        expect(subject.renderable_items.map(&:item_id)).to match_array [:open_zentao]
      end
    end
  end
end
