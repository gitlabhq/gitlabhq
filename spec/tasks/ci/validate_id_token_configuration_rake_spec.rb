# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe 'ci:validate_id_token_configuration', feature_category: :secrets_management do
  let(:task_class) { Tasks::Ci::ValidateIdTokenConfigurationTask }
  let(:task) { instance_double(task_class) }

  before do
    Rake.application.rake_require('tasks/ci/validate_id_token_configuration')
  end

  describe 'ci:validate_id_token_configuration' do
    it 'invokes Ci::ValidateIdTokenConfigurationTask#validate' do
      expect(task_class).to receive(:new).and_return(task)

      expect(task).to receive(:validate!)

      run_rake_task('ci:validate_id_token_configuration')
    end
  end
end
