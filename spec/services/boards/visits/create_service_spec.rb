# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Boards::Visits::CreateService, feature_category: :portfolio_management do
  describe '#execute' do
    let(:user) { create(:user) }

    context 'when a project board' do
      let_it_be(:project, freeze: false) { create(:project) }
      let_it_be(:board, freeze: false)   { create(:board, project: project) }

      let_it_be(:model, freeze: false) { BoardProjectRecentVisit }

      it_behaves_like 'boards recent visit create service'
    end

    context 'when a group board' do
      let_it_be(:group, freeze: false) { create(:group) }
      let_it_be(:board, freeze: false) { create(:board, group: group) }
      let_it_be(:model, freeze: false) { BoardGroupRecentVisit }

      it_behaves_like 'boards recent visit create service'
    end
  end
end
