# frozen_string_literal: true

RSpec.shared_examples 'forbidden git access' do
  let(:message) { /You can't/ }

  it 'prevents access' do
    expect { subject }.to raise_error(Gitlab::GitAccess::ForbiddenError, message)
  end
end

RSpec.shared_examples 'not-found git access' do
  let(:message) { /not found/ }

  it 'prevents access' do
    expect { subject }.to raise_error(Gitlab::GitAccess::NotFoundError, message)
  end
end
