# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Setting subscribed status of an issue', feature_category: :team_planning do
  include GraphqlHelpers

  it_behaves_like 'a subscribable resource api' do
    let_it_be(:resource) { create(:issue) }
    let(:mutation_name) { :issue_set_subscription }
  end
end
