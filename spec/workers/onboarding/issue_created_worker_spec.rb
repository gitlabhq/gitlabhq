# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Onboarding::IssueCreatedWorker, '#perform', feature_category: :onboarding do
  let_it_be(:issue) { create(:issue) }

  let(:namespace) { issue.project.namespace }

  it_behaves_like 'records an onboarding progress action', :issue_created do
    subject { described_class.new.perform(namespace.id) }
  end

  it_behaves_like 'does not record an onboarding progress action' do
    subject { described_class.new.perform(nil) }
  end

  it_behaves_like 'an idempotent worker' do
    let(:job_args) { [namespace.id] }

    it 'sets the onboarding progress action' do
      Onboarding::Progress.onboard(namespace)

      subject

      expect(Onboarding::Progress.completed?(namespace, :issue_created)).to eq(true)
    end
  end
end
