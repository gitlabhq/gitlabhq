# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Setting subscribed status of a merge request', feature_category: :code_review_workflow do
  include GraphqlHelpers

  it_behaves_like 'a subscribable resource api' do
    let_it_be(:resource) { create(:merge_request) }
    let(:mutation_name) { :merge_request_set_subscription }
  end
end
