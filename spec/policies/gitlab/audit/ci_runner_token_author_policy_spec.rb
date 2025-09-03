# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Audit::CiRunnerTokenAuthorPolicy, feature_category: :compliance_management do
  let(:user) { build(:user) }
  let(:ci_runner_token_author) do
    Gitlab::Audit::CiRunnerTokenAuthor.new(entity_type: 'Project', entity_path: 'test/project')
  end

  subject { described_class.new(user, ci_runner_token_author) }

  context 'when checking read_user permission' do
    it { is_expected.to be_allowed(:read_user) }

    context 'when user is nil' do
      let(:user) { nil }

      it { is_expected.to be_allowed(:read_user) }
    end
  end
end
