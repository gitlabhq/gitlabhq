# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::Widgets::HierarchyService::CreateService, feature_category: :portfolio_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, developers: user) }
  let_it_be(:parent_item) { create(:work_item, project: project) }

  let(:widget) { parent_item.widgets.find { |widget| widget.is_a?(WorkItems::Widgets::Hierarchy) } }

  shared_examples 'raises a WidgetError' do
    it { expect { subject }.to raise_error(described_class::WidgetError, message) }
  end

  describe '#create' do
    subject { described_class.new(widget: widget, current_user: user).after_create_in_transaction(params: params) }

    context 'when invalid params are present' do
      let(:params) { { other_parent: 'parent_work_item' } }

      it_behaves_like 'raises a WidgetError' do
        let(:message) { 'One or more arguments are invalid: other_parent.' }
      end
    end
  end
end
