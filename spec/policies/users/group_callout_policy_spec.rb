# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::GroupCalloutPolicy, feature_category: :shared do
  let_it_be(:group_callout) { create(:group_callout) }
  let(:user) { group_callout.user }

  subject(:policy) { described_class.new(user, group_callout) }

  describe 'delegation' do
    it { is_expected.to delegate_to(::UserPolicy) }
  end
end
