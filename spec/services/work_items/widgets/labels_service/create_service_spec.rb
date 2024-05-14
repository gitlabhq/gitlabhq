# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::Widgets::LabelsService::CreateService, feature_category: :team_planning do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:label1) { create(:label, project: project) }
  let_it_be(:label2) { create(:label, project: project) }
  let_it_be(:label3) { create(:label, project: project) }
  let_it_be(:current_user) { create(:user, reporter_of: project) }

  let(:work_item) { create(:work_item, project: project, labels: [label1, label2]) }
  let(:widget) { work_item.widgets.find { |widget| widget.is_a?(WorkItems::Widgets::Labels) } }
  let(:service) { described_class.new(widget: widget, current_user: current_user) }

  describe '#prepare_create_params' do
    context 'when params are set' do
      let(:params) { { add_label_ids: [label1.id], label_ids: [label2.id] } }

      it "sets params correctly" do
        expect(service.prepare_create_params(params: params)).to include(
          {
            add_label_ids: match_array([label1.id]),
            label_ids: match_array([label2.id])
          }
        )
      end

      context "and user doesn't have permissions to update labels" do
        let_it_be(:current_user) { create(:user) }

        it 'removes label params' do
          expect(service.prepare_create_params(params: params)).to be_nil
        end
      end
    end

    context 'when widget does not exist in new type' do
      let(:params) { {} }

      before do
        allow(service).to receive(:new_type_excludes_widget?).and_return(true)
      end

      it "sets label params as empty" do
        expect(service.prepare_create_params(params: params)).to include(
          {
            add_label_ids: [],
            label_ids: []
          }
        )
      end
    end
  end
end
