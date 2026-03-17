# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::CustomIssueTracker, feature_category: :team_planning do
  it_behaves_like Integrations::Base::CustomIssueTracker
end
