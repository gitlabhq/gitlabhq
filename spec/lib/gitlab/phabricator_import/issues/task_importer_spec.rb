# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Gitlab::PhabricatorImport::Issues::TaskImporter do
  let_it_be(:project) { create(:project) }

  let(:task) do
    Gitlab::PhabricatorImport::Representation::Task.new(
      {
        'phid' => 'the-phid',
        'fields' => {
          'name' => 'Title',
          'description' => {
            'raw' => '# This is markdown\n it can contain more text.'
          },
          'authorPHID' => 'PHID-USER-456',
          'ownerPHID' => 'PHID-USER-123',
          'dateCreated' => '1518688921',
          'dateClosed' => '1518789995'
        }
      }
    )
  end

  subject(:importer) { described_class.new(project, task) }

  describe '#execute' do
    let(:fake_user_finder) { instance_double(Gitlab::PhabricatorImport::UserFinder) }

    before do
      allow(fake_user_finder).to receive(:find)
      allow(importer).to receive(:user_finder).and_return(fake_user_finder)
    end

    it 'creates the issue with the expected attributes' do
      issue = importer.execute

      expect(issue.project).to eq(project)
      expect(issue).to be_persisted
      expect(issue.author).to eq(User.ghost)
      expect(issue.title).to eq('Title')
      expect(issue.description).to eq('# This is markdown\n it can contain more text.')
      expect(issue).to be_closed
      expect(issue.created_at).to eq(Time.at(1518688921))
      expect(issue.closed_at).to eq(Time.at(1518789995))
    end

    it 'does not recreate the issue when called multiple times' do
      expect { importer.execute }
        .to change { project.issues.reload.size }.from(0).to(1)
      expect { importer.execute }
        .not_to change { project.issues.reload.size }
    end

    it 'does not trigger a save when the object did not change' do
      existing_issue = create(:issue,
                              task.issue_attributes.merge(author: User.ghost))
      allow(importer).to receive(:issue).and_return(existing_issue)

      expect(existing_issue).not_to receive(:save!)

      importer.execute
    end

    it 'links the author if the author can be found' do
      author = create(:user)
      expect(fake_user_finder).to receive(:find).with('PHID-USER-456').and_return(author)

      issue = importer.execute

      expect(issue.author).to eq(author)
    end

    it 'links an assignee if the user can be found' do
      assignee = create(:user)
      expect(fake_user_finder).to receive(:find).with('PHID-USER-123').and_return(assignee)

      issue = importer.execute

      expect(issue.assignees).to include(assignee)
    end
  end
end
