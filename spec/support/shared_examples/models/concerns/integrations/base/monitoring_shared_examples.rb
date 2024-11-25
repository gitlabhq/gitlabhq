# frozen_string_literal: true

RSpec.shared_examples Integrations::Base::Monitoring do
  describe 'default values' do
    it { expect(subject.category).to eq(:monitoring) }
  end
end
