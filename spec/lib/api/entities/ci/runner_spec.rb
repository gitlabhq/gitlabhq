# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::Ci::Runner, feature_category: :runner_core do
  let_it_be(:runner) { create(:ci_runner) }

  let(:entity) { described_class.new(runner) }

  subject(:runner_entity) { entity.presented.as_json }

  it_behaves_like 'job_execution_status field', :runner
end
