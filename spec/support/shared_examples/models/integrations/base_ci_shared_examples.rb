# frozen_string_literal: true

RSpec.shared_examples Integrations::BaseCi do
  describe 'default values' do
    it { expect(subject.category).to eq(:ci) }
  end
end
