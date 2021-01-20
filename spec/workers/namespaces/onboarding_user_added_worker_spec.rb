# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::OnboardingUserAddedWorker, '#perform' do
  include AfterNextHelpers

  let_it_be(:group) { create(:group) }

  before do
    OnboardingProgress.onboard(group)
  end

  it 'registers an onboarding progress action' do
    expect_next(OnboardingProgressService, group)
      .to receive(:execute).with(action: :user_added).and_call_original

    subject.perform(group.id)

    expect(OnboardingProgress.completed?(group, :user_added)).to be(true)
  end
end
