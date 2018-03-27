require 'spec_helper'

describe IssueCollection do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:issue1) { create(:issue, project: project) }
  let(:issue2) { create(:issue, project: project) }
  let(:collection) { described_class.new([issue1, issue2]) }

  describe '#collection' do
    it 'returns the issues in the same order as the input Array' do
      expect(collection.collection).to eq([issue1, issue2])
    end
  end

  describe '#updatable_by_user' do
    context 'using an admin user' do
      it 'returns all issues' do
        user = create(:admin)

        expect(collection.updatable_by_user(user)).to eq([issue1, issue2])
      end
    end

    context 'using a user that has no access to the project' do
      it 'returns no issues when the user is not an assignee or author' do
        expect(collection.updatable_by_user(user)).to be_empty
      end

      it 'returns the issues the user is assigned to' do
        issue1.assignees << user

        expect(collection.updatable_by_user(user)).to eq([issue1])
      end

      it 'returns the issues for which the user is the author' do
        issue1.author = user

        expect(collection.updatable_by_user(user)).to eq([issue1])
      end
    end

    context 'using a user that has reporter access to the project' do
      it 'returns the issues of the project' do
        project.add_reporter(user)

        expect(collection.updatable_by_user(user)).to eq([issue1, issue2])
      end
    end

    context 'using a user that is the owner of a project' do
      it 'returns the issues of the project' do
        expect(collection.updatable_by_user(project.namespace.owner))
          .to eq([issue1, issue2])
      end
    end
  end

  describe '#visible_to' do
    it 'is an alias for updatable_by_user' do
      updatable_by_user = described_class.instance_method(:updatable_by_user)
      visible_to = described_class.instance_method(:visible_to)

      expect(visible_to).to eq(updatable_by_user)
    end
  end
end
