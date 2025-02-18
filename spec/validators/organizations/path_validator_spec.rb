# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::PathValidator, feature_category: :cell do
  let(:validator) { described_class.new(attributes: [:path]) }

  describe '.valid_path?' do
    it 'handles invalid utf8' do
      expect(described_class.valid_path?(+"a\0weird\255path")).to be_falsey
    end
  end

  describe '#validates_each' do
    it 'adds a message when the path is not in the correct format' do
      organization = build(:organization)

      validator.validate_each(organization, :path, "Path with spaces, and comma's!")

      expect(organization.errors[:path]).to include(Gitlab::PathRegex.organization_format_message)
    end

    it 'adds a message when the path is reserved when creating' do
      organization = build(:organization, path: 'help')

      validator.validate_each(organization, :path, 'help')

      expect(organization.errors[:path]).to include('help is a reserved name')
    end

    it 'adds a message when the path is reserved when updating' do
      organization = create(:organization)
      organization.path = 'help'

      validator.validate_each(organization, :path, 'help')

      expect(organization.errors[:path]).to include('help is a reserved name')
    end
  end
end
