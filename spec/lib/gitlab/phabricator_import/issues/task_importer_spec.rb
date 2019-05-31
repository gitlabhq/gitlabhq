# frozen_string_literal: true
require 'spec_helper'

describe Gitlab::PhabricatorImport::Issues::TaskImporter do
  set(:project) { create(:project) }
  let(:task) do
    Gitlab::PhabricatorImport::Representation::Task.new(
      {
        'phid' => 'the-phid',
        'fields' => {
          'name' => 'Title',
          'description' => {
            'raw' => '# This is markdown\n it can contain more text.'
          },
          'dateCreated' => '1518688921',
          'dateClosed' => '1518789995'
        }
      }
    )
  end

  describe '#execute' do
    it 'creates the issue with the expected attributes' do
      issue = described_class.new(project, task).execute

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
      expect { described_class.new(project, task).execute }
        .to change { project.issues.reload.size }.from(0).to(1)
      expect { described_class.new(project, task).execute }
        .not_to change { project.issues.reload.size }
    end

    it 'does not trigger a save when the object did not change' do
      existing_issue = create(:issue,
                              task.issue_attributes.merge(author: User.ghost))
      importer = described_class.new(project, task)
      allow(importer).to receive(:issue).and_return(existing_issue)

      expect(existing_issue).not_to receive(:save!)

      importer.execute
    end
  end
end
