# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Onboarding::UserAddedWorker, '#perform', feature_category: :onboarding do
  let_it_be(:namespace) { create(:group) }

  subject { described_class.new.perform(namespace.id) }

  it_behaves_like 'records an onboarding progress action', :user_added
end
