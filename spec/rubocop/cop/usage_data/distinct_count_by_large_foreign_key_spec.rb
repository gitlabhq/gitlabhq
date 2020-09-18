# frozen_string_literal: true

require 'fast_spec_helper'

require 'rubocop'
require 'rubocop/rspec/support'

require_relative '../../../../rubocop/cop/usage_data/distinct_count_by_large_foreign_key'

RSpec.describe RuboCop::Cop::UsageData::DistinctCountByLargeForeignKey, type: :rubocop do
  include CopHelper

  let(:allowed_foreign_keys) { [:author_id, :user_id, :'merge_requests.target_project_id'] }

  let(:config) do
    RuboCop::Config.new('UsageData/DistinctCountByLargeForeignKey' => {
                          'AllowedForeignKeys' => allowed_foreign_keys
                        })
  end

  subject(:cop) { described_class.new(config) }

  context 'when counting by disallowed key' do
    it 'registers an offence' do
      inspect_source('distinct_count(Issue, :creator_id)')

      expect(cop.offenses.size).to eq(1)
    end

    it 'does not register an offence when batch is false' do
      inspect_source('distinct_count(Issue, :creator_id, batch: false)')

      expect(cop.offenses).to be_empty
    end

    it 'register an offence when batch is true' do
      inspect_source('distinct_count(Issue, :creator_id, batch: true)')

      expect(cop.offenses.size).to eq(1)
    end
  end

  context 'when calling by allowed key' do
    it 'does not register an offence with symbol' do
      inspect_source('distinct_count(Issue, :author_id)')

      expect(cop.offenses).to be_empty
    end

    it 'does not register an offence with string' do
      inspect_source("distinct_count(Issue, 'merge_requests.target_project_id')")

      expect(cop.offenses).to be_empty
    end
  end
end
