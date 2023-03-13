# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::Github::CancelProjectImportService, feature_category: :importers do
  subject(:import_cancel) { described_class.new(project, project.owner) }

  let_it_be(:user) { create(:user) }
  let_it_be_with_reload(:project) { create(:project, :import_started, import_type: 'github', import_url: 'https://fake.url') }

  describe '.execute' do
    context 'when user is an owner' do
      context 'when import is in progress' do
        it 'update import state to be canceled' do
          expect(import_cancel.execute).to eq({ status: :success, project: project })
        end

        it 'tracks canceled imports' do
          metrics_double = instance_double('Gitlab::Import::Metrics')

          expect(Gitlab::Import::Metrics)
            .to receive(:new)
            .with(:github_importer, project)
            .and_return(metrics_double)
          expect(metrics_double).to receive(:track_canceled_import)

          import_cancel.execute
        end
      end

      context 'when import is finished' do
        let(:expected_result) do
          {
            status: :error,
            http_status: :bad_request,
            message: 'The import cannot be canceled because it is finished'
          }
        end

        before do
          project.import_state.finish!
        end

        it 'returns error' do
          expect(import_cancel.execute).to eq(expected_result)
        end
      end
    end

    context 'when user is not allowed to read project' do
      it 'returns 404' do
        expect(described_class.new(project, user).execute)
          .to eq({ status: :error, http_status: :not_found, message: 'Not Found' })
      end
    end

    context 'when user is not allowed to cancel project' do
      before do
        project.add_developer(user)
      end

      it 'returns 403' do
        expect(described_class.new(project, user).execute)
          .to eq({ status: :error, http_status: :forbidden, message: 'Unauthorized access' })
      end
    end
  end
end
