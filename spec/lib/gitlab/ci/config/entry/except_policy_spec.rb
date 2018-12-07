# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Config::Entry::ExceptPolicy do
  let(:entry) { described_class.new(config) }

  it_behaves_like 'correct only except policy'

  describe '.default' do
    it 'does not have a default value' do
      expect(described_class.default).to be_nil
    end
  end
end
