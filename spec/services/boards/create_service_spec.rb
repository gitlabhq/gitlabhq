# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Boards::CreateService, feature_category: :portfolio_management do
  describe '#execute' do
    context 'when board parent is a project' do
      let(:parent) { create(:project) }

      subject(:service) { described_class.new(parent, double) }

      it_behaves_like 'boards create service'
    end

    context 'when board parent is a group' do
      let(:parent) { create(:group) }

      subject(:service) { described_class.new(parent, double) }

      it_behaves_like 'boards create service'
    end
  end

  describe 'internal event tracking' do
    context 'when creating a project board' do
      let_it_be(:project) { create(:project) }

      it 'tracks board_created event' do
        expect { described_class.new(project, double).execute }
          .to trigger_internal_events('board_created')
          .with(project: project, namespace: project.namespace)
      end
    end

    context 'when creating a group board' do
      let_it_be(:group) { create(:group) }

      it 'tracks board_created event' do
        expect { described_class.new(group, double).execute }
          .to trigger_internal_events('board_created')
          .with(namespace: group)
      end
    end
  end
end
