# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ResourceIterationEvent, type: :model do
  it_behaves_like 'a resource event'
  it_behaves_like 'a resource event for issues'
  it_behaves_like 'a resource event for merge requests'

  it_behaves_like 'having unique enum values'
  it_behaves_like 'timebox resource event validations'
  it_behaves_like 'timebox resource event actions'

  describe 'associations' do
    it { is_expected.to belong_to(:iteration) }
  end
end
