# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::CustomAttributePolicy, feature_category: :groups_and_projects do
  let_it_be(:admin) { create(:admin) }
  let_it_be(:user) { create(:user, owner_of: group) }
  let_it_be(:group) { create(:group) }
  let_it_be(:custom_attribute) { create(:group_custom_attribute, group: group) }

  subject { described_class.new(current_user, custom_attribute) }

  it_behaves_like 'custom attribute policy'
end
