# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Boards::CreateService, feature_category: :portfolio_management do
  describe '#execute' do
    let_it_be(:user) { create(:user) }

    subject(:service) { described_class.new(parent, user) }

    context 'when board parent is a project' do
      let_it_be(:parent, reload: true) { create(:project) }

      it_behaves_like 'boards create service'

      it 'tracks board_created event' do
        expect do
          service.execute
        end.to(
          trigger_internal_events('board_created')
            .with(user: user, project: parent, namespace: parent.namespace)
        )
      end
    end

    context 'when board parent is a group' do
      let_it_be(:parent, reload: true) { create(:group) }

      it_behaves_like 'boards create service'

      it 'tracks board_created event' do
        expect do
          service.execute
        end.to(
          trigger_internal_events('board_created')
            .with(user: user, namespace: parent)
        )
      end
    end
  end
end
