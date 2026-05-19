# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::CustomAttributePolicy, feature_category: :groups_and_projects do
  let_it_be(:admin) { create(:admin) }
  let_it_be(:user) { create(:user, owner_of: project) }
  let_it_be(:project) { create(:project) }
  let_it_be(:custom_attribute) { create(:project_custom_attribute, project: project) }

  subject { described_class.new(current_user, custom_attribute) }

  it_behaves_like 'custom attribute policy'
end
