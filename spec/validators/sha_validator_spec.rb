# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ShaValidator do
  let(:validator) { described_class.new(attributes: [:base_commit_sha]) }
  let!(:merge_diff) { build(:merge_request_diff) }

  subject { validator.validate_each(merge_diff, :base_commit_sha, value) }

  context 'with empty value' do
    let(:value) { nil }

    it 'does not add any error if value is empty' do
      expect(Commit).not_to receive(:valid_hash?)

      subject

      expect(merge_diff.errors).to be_empty
    end
  end

  context 'with valid sha' do
    let(:value) { Digest::SHA1.hexdigest(SecureRandom.hex) }

    it 'does not add any error' do
      expect(Commit).to receive(:valid_hash?).and_call_original

      subject

      expect(merge_diff.errors).to be_empty
    end
  end

  context 'with invalid sha' do
    let(:value) { 'foo' }

    it 'adds error to the record' do
      expect(Commit).to receive(:valid_hash?).and_call_original
      expect(merge_diff.errors).to be_empty

      subject

      expect(merge_diff.errors).not_to be_empty
    end
  end
end
