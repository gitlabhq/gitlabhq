require 'spec_helper'

describe UserPathValidator do
  let(:validator) { described_class.new(attributes: [:username]) }

  describe '.valid_path?' do
    it 'handles invalid utf8' do
      expect(described_class.valid_path?("a\0weird\255path")).to be_falsey
    end
  end

  describe '#validates_each' do
    it 'adds a message when the path is not in the correct format' do
      user = build(:user)

      validator.validate_each(user, :username, "Path with spaces, and comma's!")

      expect(user.errors[:username]).to include(Gitlab::PathRegex.namespace_format_message)
    end

    it 'adds a message when the path is reserved when creating' do
      user = build(:user, username: 'help')

      validator.validate_each(user, :username, 'help')

      expect(user.errors[:username]).to include('help is a reserved name')
    end

    it 'adds a message when the path is reserved when updating' do
      user = create(:user)
      user.username = 'help'

      validator.validate_each(user, :username, 'help')

      expect(user.errors[:username]).to include('help is a reserved name')
    end
  end
end
