# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::OnboardingProgressWorker, '#perform' do
  let_it_be(:namespace) { create(:namespace) }
  let_it_be(:action) { 'git_pull' }

  it_behaves_like 'records an onboarding progress action', :git_pull do
    include_examples 'an idempotent worker' do
      subject { described_class.new.perform(namespace.id, action) }
    end
  end

  it_behaves_like 'does not record an onboarding progress action' do
    subject { described_class.new.perform(namespace.id, nil) }
  end

  it_behaves_like 'does not record an onboarding progress action' do
    subject { described_class.new.perform(nil, action) }
  end
end
