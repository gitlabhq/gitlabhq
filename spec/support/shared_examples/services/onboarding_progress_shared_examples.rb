# frozen_string_literal: true

RSpec.shared_examples 'records an onboarding progress action' do |action|
  include AfterNextHelpers

  it do
    expect_next(Onboarding::ProgressService, namespace)
      .to receive(:execute).with(action: action).and_call_original

    subject
  end
end

RSpec.shared_examples 'does not record an onboarding progress action' do
  it do
    expect(Onboarding::ProgressService).not_to receive(:new)

    subject
  end
end
