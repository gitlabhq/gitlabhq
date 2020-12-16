# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::OnboardingUserAddedWorker, '#perform' do
  include AfterNextHelpers

  let_it_be(:group) { create(:group) }

  it 'records the event' do
    expect_next(OnboardingProgressService, group)
      .to receive(:execute).with(action: :user_added).and_call_original

    expect { subject.perform(group.id) }.to change(NamespaceOnboardingAction, :count).by(1)
  end
end
