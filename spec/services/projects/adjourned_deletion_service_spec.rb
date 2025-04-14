# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::AdjournedDeletionService, feature_category: :groups_and_projects do
  let(:project) { create(:project, marked_for_deletion_at: 10.days.ago, marked_for_deletion_by_user_id: user&.id) }
  let(:resource) { project }
  let(:destroy_worker) { ProjectDestroyWorker }
  let(:destroy_worker_params) { [project.id, user.id, {}] }
  let(:perform_method) { :perform_async }

  subject(:service) { described_class.new(project: project, current_user: user) }

  include_examples 'adjourned deletion service'

  context 'when user cannot remove the project', :sidekiq_inline do
    context 'with deleted user' do
      let(:user) { nil }

      it_behaves_like 'user cannot remove'
    end
  end
end
