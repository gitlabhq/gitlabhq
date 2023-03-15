# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ResourceEvents::SyntheticStateNotesBuilderService, feature_category: :team_planning do
  describe '#execute' do
    let_it_be(:user) { create(:user) }

    it_behaves_like 'filters by paginated notes', :resource_state_event
  end
end
