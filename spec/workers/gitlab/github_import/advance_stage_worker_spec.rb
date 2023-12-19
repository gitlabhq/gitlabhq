# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::AdvanceStageWorker, feature_category: :importers do
  it_behaves_like Gitlab::Import::AdvanceStage, factory: :import_state

  it 'has a Sidekiq retry of 6' do
    expect(described_class.sidekiq_options['retry']).to eq(6)
  end
end
