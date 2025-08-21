# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'gitlab:permissions rake tasks', feature_category: :permissions do
  before do
    Rake.application.rake_require('tasks/gitlab/permissions/permissions')
  end

  describe 'validate' do
    it 'invokes Gitlab::Permissions::ValidateTask' do
      validate_task = instance_double(Tasks::Gitlab::Permissions::ValidateTask)

      expect(Tasks::Gitlab::Permissions::ValidateTask).to receive(:new).and_return(validate_task)

      expect(validate_task).to receive(:run)

      run_rake_task('gitlab:permissions:validate')
    end
  end
end
