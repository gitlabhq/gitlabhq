# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuthorizedProjectUpdate::ProjectAccessChangedService, feature_category: :groups_and_projects do
  describe '#execute' do
    it 'executes projects_authorizations refresh' do
      expect(AuthorizedProjectUpdate::ProjectRecalculateWorker).to receive(:bulk_perform_async)
        .with([[1], [2]])

      described_class.new([1, 2]).execute
    end
  end
end
