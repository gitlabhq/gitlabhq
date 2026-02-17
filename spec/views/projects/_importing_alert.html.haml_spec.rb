# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/_importing_alert', feature_category: :importers do
  let(:user) { build_stubbed(:user) }
  let(:import_state) { build_stubbed(:import_state, :started) }

  subject(:page_level_alert) { view.content_for(:page_level_alert) }

  before do
    allow(view).to receive(:current_user).and_return(user)
    allow(view).to receive(:can?).with(user, :read_import_error, project).and_return(has_permission)
    render 'projects/importing_alert', project: project
  end

  context 'when import has failed' do
    let(:repository) { instance_double(Repository, exists?: repository_exists) }
    let(:import_state) { build_stubbed(:import_state, :failed, last_error: "Connection timed out") }
    let(:project) do
      instance_double(
        Project,
        import_in_progress?: false,
        import_failed?: true,
        import_state: import_state,
        repository: repository
      )
    end

    context 'when no repository exists' do
      let(:repository_exists) { false }

      context 'when user does not have permission to read import errors' do
        let(:has_permission) { false }

        it 'does not render the failed import alert' do
          expect(page_level_alert).to be_blank
        end
      end

      context 'when user has permission to read import errors' do
        let(:has_permission) { true }

        it 'renders the failed import alert with error details' do
          expect(page_level_alert).to have_text('The repository could not be imported.')
          expect(page_level_alert).to have_text('Connection timed out')
        end
      end
    end

    context 'when a repository exists' do
      let(:repository_exists) { true }

      context 'when user has permission to read import errors' do
        let(:has_permission) { true }

        it 'does not render the failed import alert' do
          expect(page_level_alert).to be_blank
        end
      end

      context 'when user does not have permission to read import errors' do
        let(:has_permission) { false }

        it 'does not render the failed import alert' do
          expect(page_level_alert).to be_nil
        end
      end
    end
  end

  context 'when import is neither failed nor in progress' do
    let(:has_permission) { true }
    let(:project) do
      instance_double(
        Project,
        import_in_progress?: false,
        import_failed?: false,
        import_state: import_state
      )
    end

    it 'does not show any alert' do
      expect(page_level_alert).to be_blank
    end
  end
end
