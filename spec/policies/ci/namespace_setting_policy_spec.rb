# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::NamespaceSettingPolicy, feature_category: :pipeline_composition do
  subject(:policy) { described_class.new(user, namespace_setting) }

  let_it_be(:user) { create(:user) }
  let_it_be(:namespace) { create(:namespace) }
  let_it_be(:namespace_setting) { build(:namespace_settings, namespace: namespace) }

  describe 'delegation' do
    it { is_expected.to delegate_to(::Namespaces::UserNamespacePolicy) }
  end
end
