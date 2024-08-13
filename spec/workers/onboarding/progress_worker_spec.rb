# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Onboarding::ProgressWorker, '#perform', feature_category: :onboarding do
  let_it_be(:namespace) { create(:namespace) }
  let_it_be(:action) { 'git_write' }

  it_behaves_like 'records an onboarding progress action', :git_write do
    subject { described_class.new.perform(namespace.id, action) }
  end

  it_behaves_like 'an idempotent worker' do
    let(:job_args) { [namespace.id, action] }
  end

  it_behaves_like 'does not record an onboarding progress action' do
    subject { described_class.new.perform(namespace.id, nil) }
  end

  it_behaves_like 'does not record an onboarding progress action' do
    subject { described_class.new.perform(nil, action) }
  end
end
