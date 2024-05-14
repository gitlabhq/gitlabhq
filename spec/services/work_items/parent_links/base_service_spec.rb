# frozen_string_literal: true

require 'spec_helper'

module WorkItems
  class ParentLinksService < WorkItems::ParentLinks::BaseService; end
end

RSpec.describe WorkItems::ParentLinks::BaseService, feature_category: :portfolio_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, reporters: user) }
  let_it_be(:work_item) { create(:work_item, :objective, project: project) }
  let_it_be(:target_work_item) { create(:work_item, :objective, project: project) }

  let(:params) { { target_issuable: target_work_item } }
  let(:described_class_descendant) { WorkItems::ParentLinksService }

  describe '#execute' do
    subject { described_class_descendant.new(work_item, user, params).execute }

    context 'when user has sufficient permissions' do
      it 'raises NotImplementedError' do
        expect { subject }.to raise_error(NotImplementedError)
      end
    end
  end
end
