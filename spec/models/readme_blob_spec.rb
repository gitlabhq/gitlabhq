# frozen_string_literal: true

require 'spec_helper'

describe ReadmeBlob do
  include FakeBlobHelpers

  describe 'policy' do
    let(:project) { build(:project, :repository) }

    subject { described_class.new(fake_blob(path: 'README.md'), project.repository) }

    it 'works with policy' do
      expect(Ability.allowed?(project.creator, :read_blob, subject)).to be_truthy
    end
  end
end
