# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::RunnerPolicy, feature_category: :runner do
  let_it_be(:owner) { create(:user) }

  describe 'ability :read_runner' do
    subject(:policy) { described_class.new(user, runner) }

    it_behaves_like 'runner read policy', :read_runner
  end

  describe 'ability :read_ephemeral_token' do
    subject(:policy) { described_class.new(user, runner) }

    let_it_be(:runner) { create(:ci_runner, creator: owner) }

    let(:creator) { owner }

    context 'with request made by creator' do
      let(:user) { creator }

      it { expect_allowed :read_ephemeral_token }
    end

    context 'with request made by another user' do
      let(:user) { create(:admin) }

      it { expect_disallowed :read_ephemeral_token }
    end
  end
end
