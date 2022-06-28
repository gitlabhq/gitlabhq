# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::Widgets::DescriptionService::UpdateService do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be_with_reload(:work_item) { create(:work_item, project: project, description: 'old description') }

  let(:widget) { work_item.widgets.find {|widget| widget.is_a?(WorkItems::Widgets::Description) } }

  describe '#update' do
    subject { described_class.new(widget: widget, current_user: user).update(params: params) } # rubocop:disable Rails/SaveBang

    context 'when description param is present' do
      let(:params) { { description: 'updated description' } }

      it 'correctly sets work item description value' do
        subject

        expect(work_item.description).to eq('updated description')
      end
    end

    context 'when description param is not present' do
      let(:params) { {} }

      it 'does not change work item description value' do
        subject

        expect(work_item.description).to eq('old description')
      end
    end
  end
end
