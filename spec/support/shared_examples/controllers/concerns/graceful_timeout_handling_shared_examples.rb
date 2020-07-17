# frozen_string_literal: true

RSpec.shared_examples GracefulTimeoutHandling do
  it 'includes GracefulTimeoutHandling' do
    expect(controller).to be_a(GracefulTimeoutHandling)
  end
end
