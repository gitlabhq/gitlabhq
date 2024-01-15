# frozen_string_literal: true

require 'spec_helper'

# Most tests of StageMethods should not go here but in the shared examples instead:
# spec/support/shared_examples/workers/gitlab/github_import/stage_methods_shared_examples.rb
RSpec.describe Gitlab::GithubImport::StageMethods, feature_category: :importers do
  let(:worker) do
    Class.new do
      def self.name
        'DummyStage'
      end

      include(Gitlab::GithubImport::StageMethods)
    end.new
  end

  describe '.max_retries_after_interruption!' do
    subject(:max_retries_after_interruption) { worker.class.sidekiq_options['max_retries_after_interruption'] }

    it 'does not set the `max_retries_after_interruption` if not called' do
      is_expected.to be_nil
    end

    it 'sets the `max_retries_after_interruption`' do
      worker.class.resumes_work_when_interrupted!

      is_expected.to eq(20)
    end
  end
end
