# frozen_string_literal: true

require 'spec_helper'

RSpec.describe LooseForeignKeys::TurboModificationTracker, feature_category: :database do
  subject(:tracker) { described_class.new }

  let(:normal_tracker) { LooseForeignKeys::ModificationTracker.new }

  context 'with limits should be higher than LooseForeignKeys::ModificationTracker' do
    it 'expect max_deletes to be equal or higher' do
      expect(tracker.max_deletes).to be >= normal_tracker.max_deletes
    end

    it 'expect max_updates to be equal or higher' do
      expect(tracker.max_updates).to be >= normal_tracker.max_updates
    end

    it 'expect max_runtime to be equal or higher' do
      expect(tracker.max_runtime).to be >= normal_tracker.max_runtime
    end
  end
end
