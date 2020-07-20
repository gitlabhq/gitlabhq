# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ApprovableBase do
  let(:merge_request) { create(:merge_request) }
  let(:user) { create(:user) }

  describe '#approved_by?' do
    subject { merge_request.approved_by?(user) }

    context 'when a user has not approved' do
      it 'returns false' do
        is_expected.to be_falsy
      end
    end

    context 'when a user has approved' do
      let!(:approval) { create(:approval, merge_request: merge_request, user: user) }

      it 'returns false' do
        is_expected.to be_truthy
      end
    end

    context 'when a user is nil' do
      let(:user) { nil }

      it 'returns false' do
        is_expected.to be_falsy
      end
    end
  end

  describe '#can_be_approved_by?' do
    subject { merge_request.can_be_approved_by?(user) }

    before do
      merge_request.project.add_developer(user)
    end

    it 'returns true' do
      is_expected.to be_truthy
    end

    context 'when a user has approved' do
      let!(:approval) { create(:approval, merge_request: merge_request, user: user) }

      it 'returns false' do
        is_expected.to be_falsy
      end
    end

    context 'when a user is nil' do
      let(:user) { nil }

      it 'returns false' do
        is_expected.to be_falsy
      end
    end
  end
end
