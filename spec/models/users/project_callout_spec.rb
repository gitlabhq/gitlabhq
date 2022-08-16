# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::ProjectCallout do
  let_it_be(:user) { create_default(:user) }
  let_it_be(:project) { create_default(:project) }
  let_it_be(:callout) { create(:project_callout) }

  it_behaves_like 'having unique enum values'

  describe 'relationships' do
    it { is_expected.to belong_to(:project) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_presence_of(:feature_name) }

    it {
      is_expected.to validate_uniqueness_of(:feature_name).scoped_to(:user_id, :project_id).ignoring_case_sensitivity
    }
  end
end
