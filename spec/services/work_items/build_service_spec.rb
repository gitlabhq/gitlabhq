# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::BuildService, feature_category: :team_planning do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:guest) { create(:user) }

  let(:user) { guest }

  before_all do
    project.add_guest(guest)
  end

  describe '#execute' do
    subject { described_class.new(container: project, current_user: user, params: {}).execute }

    it { is_expected.to be_a(::WorkItem) }
  end
end
