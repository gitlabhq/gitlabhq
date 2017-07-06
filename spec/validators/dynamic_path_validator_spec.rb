require 'spec_helper'

describe DynamicPathValidator do
  let(:validator) { described_class.new(attributes: [:path]) }

  def expect_handles_invalid_utf8
    expect { yield('\255invalid') }.to be_falsey
  end

  describe '.valid_user_path' do
    it 'handles invalid utf8' do
      expect(described_class.valid_user_path?("a\0weird\255path")).to be_falsey
    end
  end

  describe '.valid_group_path' do
    it 'handles invalid utf8' do
      expect(described_class.valid_group_path?("a\0weird\255path")).to be_falsey
    end
  end

  describe '.valid_project_path' do
    it 'handles invalid utf8' do
      expect(described_class.valid_project_path?("a\0weird\255path")).to be_falsey
    end
  end

  describe '#path_valid_for_record?' do
    context 'for project' do
      it 'calls valid_project_path?' do
        project = build(:project, path: 'activity')

        expect(described_class).to receive(:valid_project_path?).with(project.full_path).and_call_original

        expect(validator.path_valid_for_record?(project, 'activity')).to be_truthy
      end
    end

    context 'for group' do
      it 'calls valid_group_path?' do
        group = build(:group, :nested, path: 'activity')

        expect(described_class).to receive(:valid_group_path?).with(group.full_path).and_call_original

        expect(validator.path_valid_for_record?(group, 'activity')).to be_falsey
      end
    end

    context 'for user' do
      it 'calls valid_user_path?' do
        user = build(:user, username: 'activity')

        expect(described_class).to receive(:valid_user_path?).with(user.full_path).and_call_original

        expect(validator.path_valid_for_record?(user, 'activity')).to be_truthy
      end
    end

    context 'for user namespace' do
      it 'calls valid_user_path?' do
        user = create(:user, username: 'activity')
        namespace = user.namespace

        expect(described_class).to receive(:valid_user_path?).with(namespace.full_path).and_call_original

        expect(validator.path_valid_for_record?(namespace, 'activity')).to be_truthy
      end
    end
  end

  describe '#validates_each' do
    it 'adds a message when the path is not in the correct format' do
      group = build(:group)

      validator.validate_each(group, :path, "Path with spaces, and comma's!")

      expect(group.errors[:path]).to include(Gitlab::PathRegex.namespace_format_message)
    end

    it 'adds a message when the path is not in the correct format' do
      group = build(:group, path: 'users')

      validator.validate_each(group, :path, 'users')

      expect(group.errors[:path]).to include('users is a reserved name')
    end

    it 'updating to an invalid path is not allowed' do
      project = create(:empty_project)
      project.path = 'update'

      validator.validate_each(project, :path, 'update')

      expect(project.errors[:path]).to include('update is a reserved name')
    end
  end
end
