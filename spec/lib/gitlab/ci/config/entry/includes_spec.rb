# frozen_string_literal: true

require 'fast_spec_helper'
require_dependency 'active_model'

RSpec.describe ::Gitlab::Ci::Config::Entry::Includes, feature_category: :pipeline_composition do
  subject(:include_entry) { described_class.new(config) }

  describe '#initialize' do
    let(:config) { 'test.yml' }

    it 'does not increase aspects' do
      2.times { expect { described_class.new(config) }.not_to change { described_class.aspects.count } }
    end
  end

  describe 'validations' do
    let(:config) { [1, 2] }

    let(:includes_entry) { described_class.new(config, max_size: 1) }

    it 'returns invalid' do
      expect(includes_entry).not_to be_valid
    end

    it 'returns the appropriate error' do
      expect(includes_entry.errors).to include('includes config is too long (maximum is 1)')
    end
  end
end
