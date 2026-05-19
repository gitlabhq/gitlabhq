# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::AdjournedDeletionService, feature_category: :groups_and_projects do
  let(:project) { create(:project, :aimed_for_deletion, marked_for_deletion_at: 10.days.ago).reload }

  let(:resource) { project }
  let(:destroy_worker) { ProjectDestroyWorker }
  let(:destroy_worker_params) { [project.id, user.id, {}] }
  let(:perform_method) { :perform_async }

  subject(:service) { described_class.new(project: project, current_user: user) }

  include_examples 'adjourned deletion service'
end
