# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'gitlab_transactions_stack cleanup', feature_category: :database do
  before_all do
    # Manually pollute the stack to simulate a leftover transaction
    ApplicationRecord.gitlab_transactions_stack.push(:gitlab_main)
    ApplicationRecord.gitlab_transactions_stack.push(:gitlab_ci)
  end

  it 'has a clean stack at the start' do
    expect(ApplicationRecord.gitlab_transactions_stack).to be_empty
  end
end
