# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Boards::Visits::CreateService do
  describe '#execute' do
    let(:user) { create(:user) }

    context 'when a project board' do
      let_it_be(:project) { create(:project) }
      let_it_be(:board)   { create(:board, project: project) }

      let_it_be(:model) { BoardProjectRecentVisit }

      it_behaves_like 'boards recent visit create service'
    end

    context 'when a group board' do
      let_it_be(:group) { create(:group) }
      let_it_be(:board) { create(:board, group: group) }
      let_it_be(:model) { BoardGroupRecentVisit }

      it_behaves_like 'boards recent visit create service'
    end
  end
end
