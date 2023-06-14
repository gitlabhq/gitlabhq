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
end
