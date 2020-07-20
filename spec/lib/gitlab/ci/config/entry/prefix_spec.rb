# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::Entry::Prefix do
  let(:entry) { described_class.new(config) }

  describe 'validations' do
    it_behaves_like 'key entry validations', :prefix

    context 'when entry value is not correct' do
      let(:config) { ['incorrect'] }

      describe '#errors' do
        it 'saves errors' do
          expect(entry.errors)
            .to include 'prefix config should be a string or symbol'
        end
      end
    end
  end

  describe '.default' do
    it 'returns default key' do
      expect(described_class.default).to be_nil
    end
  end
end
