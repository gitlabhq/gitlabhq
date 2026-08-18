# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::SavedViewPolicy, feature_category: :code_review_workflow do
  let_it_be(:owner) { create(:user) }
  let_it_be(:other_user) { create(:user) }
  let_it_be(:admin) { create(:user, :admin) }
  let_it_be(:owned_view) { create(:merge_request_saved_view, :with_filters, user: owner) }

  let(:current_user) { owner }

  subject(:policy) { described_class.new(current_user, owned_view) }

  shared_examples 'an owner-only ability' do |ability|
    context 'when the current user is the owner' do
      it { expect_allowed(ability) }
    end

    context 'when the current user is not the owner' do
      let(:current_user) { other_user }

      it { expect_disallowed(ability) }
    end

    context 'when the current user is anonymous' do
      let(:current_user) { nil }

      it { expect_disallowed(ability) }
    end

    context 'when the current user is a non-owner admin with admin mode enabled', :enable_admin_mode do
      let(:current_user) { admin }

      it { expect_disallowed(ability) }
    end
  end

  describe ':read_saved_view' do
    it_behaves_like 'an owner-only ability', :read_saved_view
  end

  describe ':update_saved_view' do
    it_behaves_like 'an owner-only ability', :update_saved_view
  end

  describe ':delete_saved_view' do
    it_behaves_like 'an owner-only ability', :delete_saved_view
  end

  describe ':create_saved_view' do
    it 'is not granted by this policy, since create is authorized against the User in UserPolicy' do
      expect_disallowed(:create_saved_view)
    end

    context 'when the current user is not the owner' do
      let(:current_user) { other_user }

      it { expect_disallowed(:create_saved_view) }
    end

    context 'when the current user is anonymous' do
      let(:current_user) { nil }

      it { expect_disallowed(:create_saved_view) }
    end
  end

  context 'when the actor is anonymous' do
    subject { described_class.new(nil, owned_view) }

    it_behaves_like 'prevent all'
  end

  context 'when the actor is not a User but shares the id of the owner' do
    let(:current_user) { build_stubbed(:deploy_token, id: owner.id) }

    it { expect_disallowed(:read_saved_view, :update_saved_view, :delete_saved_view) }
  end
end
