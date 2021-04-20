# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::API::Entities::MergeRequestChanges do
  let_it_be(:user) { create(:user) }
  let_it_be(:merge_request) { create(:merge_request) }

  let(:entity) { described_class.new(merge_request, current_user: user) }

  subject(:basic_entity) { entity.as_json }

  it "exposes basic entity fields" do
    is_expected.to include(:changes, :overflow)
  end

  context "when #expose_raw_diffs? returns false" do
    before do
      expect(entity).to receive(:expose_raw_diffs?).twice.and_return(false)
      expect_any_instance_of(Gitlab::Git::DiffCollection).to receive(:overflow?)
    end

    it "does not access merge_request.raw_diffs" do
      expect(merge_request).not_to receive(:raw_diffs)

      basic_entity
    end
  end

  context "when #expose_raw_diffs? returns true" do
    before do
      expect(entity).to receive(:expose_raw_diffs?).twice.and_return(true)
      expect_any_instance_of(Gitlab::Git::DiffCollection).not_to receive(:overflow?)
    end

    it "does not access merge_request.raw_diffs" do
      expect(merge_request).to receive(:raw_diffs)

      basic_entity
    end
  end

  describe ":overflow field" do
    context "when :access_raw_diffs is true" do
      let_it_be(:entity_with_raw_diffs) do
        described_class.new(merge_request, current_user: user, access_raw_diffs: true).as_json
      end

      before do
        expect_any_instance_of(Gitlab::Git::DiffCollection).not_to receive(:overflow?)
      end

      it "reports false" do
        expect(entity_with_raw_diffs[:overflow]).to be_falsy
      end
    end
  end
end
