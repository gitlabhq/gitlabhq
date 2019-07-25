# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Build::Credentials::Factory do
  let(:build) { create(:ci_build, name: 'spinach', stage: 'test', stage_idx: 0) }

  subject { described_class.new(build).create! }

  class TestProvider
    def initialize(build); end
  end

  before do
    allow_any_instance_of(described_class).to receive(:providers).and_return([TestProvider])
  end

  context 'when provider is valid' do
    before do
      allow_any_instance_of(TestProvider).to receive(:valid?).and_return(true)
    end

    it 'generates an array of credentials objects' do
      is_expected.to be_kind_of(Array)
      is_expected.not_to be_empty
      expect(subject.first).to be_kind_of(TestProvider)
    end
  end

  context 'when provider is not valid' do
    before do
      allow_any_instance_of(TestProvider).to receive(:valid?).and_return(false)
    end

    it 'generates an array without specific credential object' do
      is_expected.to be_kind_of(Array)
      is_expected.to be_empty
    end
  end
end
