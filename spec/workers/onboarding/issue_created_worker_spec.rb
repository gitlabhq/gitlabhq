# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Onboarding::IssueCreatedWorker, '#perform', feature_category: :onboarding do
  specify do
    expect { described_class.new.perform(non_existing_record_id) }.not_to raise_error
  end
end
