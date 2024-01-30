# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::ProjectImportStatus, :aggregate_failures, feature_category: :importers do
  describe '#as_json' do
    subject { entity.as_json }

    let(:correlation_id) { 'cid' }

    context 'when no import state exists' do
      let(:entity) { described_class.new(build(:project, import_type: 'import_type')) }

      it 'includes basic fields and no failures' do
        expect(subject[:import_status]).to eq('none')
        expect(subject[:import_type]).to eq('import_type')
        expect(subject[:correlation_id]).to be_nil
        expect(subject[:import_error]).to be_nil
        expect(subject[:failed_relations]).to eq([])
        expect(subject[:stats]).to be_nil
      end
    end

    context 'when import has not finished yet' do
      let(:project) { create(:project, :import_scheduled, import_type: 'import_type', import_correlation_id: correlation_id) }
      let(:entity) { described_class.new(project, import_type: 'import_type') }

      it 'includes basic fields and no failures' do
        expect(subject[:import_status]).to eq('scheduled')
        expect(subject[:import_type]).to eq('import_type')
        expect(subject[:correlation_id]).to eq(correlation_id)
        expect(subject[:import_error]).to be_nil
        expect(subject[:failed_relations]).to eq([])
      end
    end

    context 'when import has finished with failed relations' do
      let(:project) { create(:project, :import_finished, import_type: 'import_type', import_correlation_id: correlation_id) }
      let(:entity) { described_class.new(project) }

      it 'includes basic fields with failed relations' do
        create(
          :import_failure,
          :hard_failure,
          project: project,
          correlation_id_value: correlation_id,
          relation_key: 'issues',
          relation_index: 1
        )

        # Doesn't show soft failures
        create(:import_failure, :soft_failure)

        expect(subject[:import_status]).to eq('finished')
        expect(subject[:import_type]).to eq('import_type')
        expect(subject[:correlation_id]).to eq(correlation_id)
        expect(subject[:import_error]).to be_nil
        expect(subject[:failed_relations].length).to eq(1)

        failure = subject[:failed_relations].last
        expect(failure[:exception_class]).to eq('RuntimeError')
        expect(failure[:source]).to eq('method_call')
        expect(failure[:relation_name]).to eq('issues')
        expect(failure[:line_number]).to eq(1)
      end
    end

    context 'when import has failed' do
      let(:project) { create(:project, :import_failed, import_type: 'import_type', import_correlation_id: correlation_id, import_last_error: 'error') }
      let(:current_user) { create(:user) }
      let(:options) { { current_user: current_user } }
      let(:entity) { described_class.new(project, options) }

      context 'when user has access to read import status' do
        before do
          project.add_maintainer(current_user)
        end

        it 'includes basic fields with import error' do
          expect(subject[:import_status]).to eq('failed')
          expect(subject[:import_type]).to eq('import_type')
          expect(subject[:correlation_id]).to eq(correlation_id)
          expect(subject[:import_error]).to eq('error')
          expect(subject[:failed_relations]).to eq([])
        end
      end

      context 'when user does not have access to read import status' do
        before do
          project.add_reporter(current_user)
        end

        it 'includes basic fields with import error' do
          expect(subject[:import_status]).to eq('failed')
          expect(subject[:import_type]).to eq('import_type')
          expect(subject[:correlation_id]).to eq(correlation_id)
          expect(subject[:import_error]).to eq('Ask a maintainer to check the import status for more details.')
          expect(subject[:failed_relations]).to eq([])
        end
      end
    end

    context 'when importing from github', :clean_gitlab_redis_shared_state do
      let(:project) { create(:project, :import_failed, import_type: 'github') }
      let(:entity) { described_class.new(project) }

      before do
        ::Gitlab::GithubImport::ObjectCounter.increment(project, :issues, :fetched, value: 10)
        ::Gitlab::GithubImport::ObjectCounter.increment(project, :issues, :imported, value: 8)
      end

      it 'exposes the import stats' do
        expect(subject[:stats]).to eq(
          'fetched' => { 'issues' => 10 },
          'imported' => { 'issues' => 8 }
        )
      end
    end
  end
end
