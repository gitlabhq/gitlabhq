# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Checks::ForcePush, feature_category: :source_code_management do
  let_it_be(:project) { create(:project, :repository) }

  describe '.force_push?' do
    let(:old_rev) { 'HEAD~' }
    let(:new_rev) { 'HEAD' }

    subject(:force_push) { described_class.force_push?(project, old_rev, new_rev) }

    context 'when the repo is empty' do
      before do
        allow(project).to receive(:empty_repo?).and_return(true)
      end

      it 'returns false' do
        expect(force_push).to be(false)
      end
    end

    context 'when new rev is a descendant of old rev' do
      it 'returns false' do
        expect(force_push).to be(false)
      end
    end

    context 'when new rev is not a descendant of old rev' do
      let(:old_rev) { 'HEAD' }
      let(:new_rev) { 'HEAD~' }

      it 'returns true' do
        expect(force_push).to be(true)
      end
    end
  end
end
