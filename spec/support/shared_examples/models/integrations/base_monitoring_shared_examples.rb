# frozen_string_literal: true

RSpec.shared_examples Integrations::BaseMonitoring do
  describe 'default values' do
    it { expect(subject.category).to eq(:monitoring) }
  end
end
