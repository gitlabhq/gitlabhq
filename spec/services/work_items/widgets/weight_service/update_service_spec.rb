# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::Widgets::WeightService::UpdateService do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be_with_reload(:work_item) { create(:work_item, project: project, weight: 1) }

  let(:widget) { work_item.widgets.find {|widget| widget.is_a?(WorkItems::Widgets::Weight) } }

  describe '#update' do
    subject { described_class.new(widget: widget, current_user: user).update(params: params) } # rubocop:disable Rails/SaveBang

    context 'when weight param is present' do
      let(:params) { { weight: 2 } }

      it 'correctly sets work item weight value' do
        subject

        expect(work_item.weight).to eq(2)
      end
    end

    context 'when weight param is not present' do
      let(:params) { {} }

      it 'does not change work item weight value', :aggregate_failures do
        expect { subject }
          .to not_change { work_item.weight }

        expect(work_item.weight).to eq(1)
      end
    end
  end
end
