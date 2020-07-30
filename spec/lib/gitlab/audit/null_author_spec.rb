# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Audit::NullAuthor do
  subject { described_class }

  describe '.for' do
    it 'returns an DeletedAuthor' do
      expect(subject.for(666, 'Old Hat')).to be_a(Gitlab::Audit::DeletedAuthor)
    end

    it 'returns an UnauthenticatedAuthor when id equals -1', :aggregate_failures do
      expect(subject.for(-1, 'Frank')).to be_a(Gitlab::Audit::UnauthenticatedAuthor)
      expect(subject.for(-1, 'Frank')).to have_attributes(id: -1, name: 'Frank')
    end
  end

  describe '#current_sign_in_ip' do
    it { expect(subject.new(id: 888, name: 'Guest').current_sign_in_ip).to be_nil }
  end
end
