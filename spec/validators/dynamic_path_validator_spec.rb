require 'spec_helper'

describe DynamicPathValidator do
  let(:validator) { described_class.new(attributes: [:path]) }

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
  end
end
