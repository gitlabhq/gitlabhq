# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::JobToken::LogAuthorizationWorker, feature_category: :secrets_management do
  describe '#perform' do
    let_it_be(:origin_project) { build_stubbed(:project) }
    let_it_be(:accessed_project) { build_stubbed(:project) }

    subject(:perform) { described_class.new.perform(*job_args) }

    it_behaves_like 'an idempotent worker' do
      let(:job_args) { [accessed_project.id, origin_project.id, ['read_jobs']] }

      it 'calls Ci::JobToken::Authorization#log_captures!' do
        expect(Ci::JobToken::Authorization)
          .to receive(:log_captures!)
          .with(accessed_project_id: accessed_project.id, origin_project_id: origin_project.id, policies: [:read_jobs])
          .and_call_original

        perform
      end
    end
  end
end
