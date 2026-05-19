# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CustomAttributePolicy, feature_category: :system_access do
  let(:subclass) { Class.new(described_class) }

  let(:permissions) { %i[read_custom_attribute update_custom_attribute delete_custom_attribute] }
  let(:custom_attribute) { build_stubbed(:user_custom_attribute) }

  subject { subclass.new(current_user, custom_attribute) }

  context 'when user is admin', :enable_admin_mode do
    let(:current_user) { build_stubbed(:admin) }

    it { expect_allowed(*permissions) }
  end

  context 'when user is not admin' do
    let(:current_user) { build_stubbed(:user) }

    it { expect_disallowed(*permissions) }
  end

  context 'when user is anonymous' do
    let(:current_user) { nil }

    it { expect_disallowed(*permissions) }
  end
end
