# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Audit::DeployTokenAuthorPolicy, feature_category: :compliance_management do
  let(:deploy_token_author) { Gitlab::Audit::DeployTokenAuthor.new(name: 'Deploy Token') }
  let(:user) { build(:user) }

  subject { described_class.new(user, deploy_token_author) }

  context 'when checking read_user permission' do
    it { is_expected.to be_allowed(:read_user) }

    context 'when user is nil' do
      let(:user) { nil }

      it { is_expected.to be_allowed(:read_user) }
    end
  end
end
