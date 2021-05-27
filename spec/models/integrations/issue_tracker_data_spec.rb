# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::IssueTrackerData do
  describe 'associations' do
    it { is_expected.to belong_to :integration }
  end
end
