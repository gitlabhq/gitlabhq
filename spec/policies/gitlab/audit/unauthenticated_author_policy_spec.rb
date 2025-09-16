# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Audit::UnauthenticatedAuthorPolicy, feature_category: :compliance_management do
  let(:unauthenticated_author) { Gitlab::Audit::UnauthenticatedAuthor.new }
  let(:user) { build(:user) }

  subject { described_class.new(user, unauthenticated_author) }

  describe 'read_user' do
    it { is_expected.to be_allowed(:read_user) }

    context 'when user is admin' do
      let(:user) { build :admin }

      it { is_expected.to be_allowed(:read_user) }
    end

    context 'when user is nil' do
      let(:user) { nil }

      it { is_expected.to be_allowed(:read_user) }
    end
  end
end
