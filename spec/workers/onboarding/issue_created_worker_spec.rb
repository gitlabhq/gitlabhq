# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Onboarding::IssueCreatedWorker, '#perform', feature_category: :onboarding do
  let_it_be(:issue) { create(:issue) }

  let(:namespace) { issue.project.namespace }

  it_behaves_like 'does not record an onboarding progress action' do
    subject { described_class.new.perform(namespace.id) }
  end
end
