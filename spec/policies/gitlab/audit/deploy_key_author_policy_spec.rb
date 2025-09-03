# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Audit::DeployKeyAuthorPolicy, feature_category: :compliance_management do
  let(:deploy_key_author) { Gitlab::Audit::DeployKeyAuthor.new(name: 'Deploy Key') }
  let(:user) { build(:user) }

  subject { described_class.new(user, deploy_key_author) }

  context 'when checking read_user permission' do
    it { is_expected.to be_allowed(:read_user) }

    context 'when user is nil' do
      let(:user) { nil }

      it { is_expected.to be_allowed(:read_user) }
    end
  end
end
