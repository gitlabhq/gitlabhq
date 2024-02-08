# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::RefreshImportJidWorker, feature_category: :importers do
  let(:worker) { described_class.new }

  describe '.perform_in_the_future' do
    it 'calls Gitlab::Import::RefreshImportJidWorker#perform_in_the_future' do
      expect(Gitlab::Import::RefreshImportJidWorker)
        .to receive(:perform_in_the_future)
        .with(10, '123')

      described_class.perform_in_the_future(10, '123')
    end
  end
end
