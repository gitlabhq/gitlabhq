require 'spec_helper'

describe Gitlab::PhabricatorImport::Representation::Task do
  subject(:task) do
    described_class.new(
      {
        'phid' => 'the-phid',
        'fields' => {
          'name' => 'Title'.ljust(257, '.'), # A string padded to 257 chars
          'description' => {
            'raw' => '# This is markdown\n it can contain more text.'
          },
          'dateCreated' => '1518688921',
          'dateClosed' => '1518789995'
        }
      }
    )
  end

  describe '#issue_attributes' do
    it 'contains the expected values' do
      expected_attributes = {
        title: 'Title'.ljust(255, '.'),
        description: '# This is markdown\n it can contain more text.',
        state: :closed,
        created_at: Time.at(1518688921),
        closed_at: Time.at(1518789995)
      }

      expect(task.issue_attributes).to eq(expected_attributes)
    end
  end
end
