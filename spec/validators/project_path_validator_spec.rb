require 'spec_helper'

describe ProjectPathValidator do
  let(:validator) { described_class.new(attributes: [:path]) }

  describe '.valid_path?' do
    it 'handles invalid utf8' do
      expect(described_class.valid_path?("a\0weird\255path")).to be_falsey
    end
  end

  describe '#validates_each' do
    it 'adds a message when the path is not in the correct format' do
      project = build(:project)

      validator.validate_each(project, :path, "Path with spaces, and comma's!")

      expect(project.errors[:path]).to include(Gitlab::PathRegex.project_path_format_message)
    end

    it 'adds a message when the path is reserved when creating' do
      project = build(:project, path: 'blob')

      validator.validate_each(project, :path, 'blob')

      expect(project.errors[:path]).to include('blob is a reserved name')
    end

    it 'adds a message when the path is reserved when updating' do
      project = create(:project)
      project.path = 'blob'

      validator.validate_each(project, :path, 'blob')

      expect(project.errors[:path]).to include('blob is a reserved name')
    end
  end
end
