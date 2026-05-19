# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::CustomAttributePolicy, feature_category: :user_profile do
  let_it_be(:admin) { create(:admin) }
  let_it_be(:user) { create(:user) }
  let_it_be(:target_user) { create(:user) }
  let_it_be(:custom_attribute) { create(:user_custom_attribute, user: target_user) }

  subject { described_class.new(current_user, custom_attribute) }

  it_behaves_like 'custom attribute policy'
end
