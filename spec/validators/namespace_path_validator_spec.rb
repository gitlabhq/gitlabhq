require 'spec_helper'

describe NamespacePathValidator do
  let(:validator) { described_class.new(attributes: [:path]) }

  describe '.valid_path?' do
    it 'handles invalid utf8' do
      expect(described_class.valid_path?("a\0weird\255path")).to be_falsey
    end
  end

  describe '#validates_each' do
    it 'adds a message when the path is not in the correct format' do
      group = build(:group)

      validator.validate_each(group, :path, "Path with spaces, and comma's!")

      expect(group.errors[:path]).to include(Gitlab::PathRegex.namespace_format_message)
    end

    it 'adds a message when the path is reserved when creating' do
      group = build(:group, path: 'help')

      validator.validate_each(group, :path, 'help')

      expect(group.errors[:path]).to include('help is a reserved name')
    end

    it 'adds a message when the path is reserved when updating' do
      group = create(:group)
      group.path = 'help'

      validator.validate_each(group, :path, 'help')

      expect(group.errors[:path]).to include('help is a reserved name')
    end
  end
end
