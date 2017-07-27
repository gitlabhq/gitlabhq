require 'rails_helper'

describe MergeRequestDiffFile do
  describe '#utf8_diff' do
    it 'does not raise error when a hash value is in binary' do
      subject.diff = "\x05\x00\x68\x65\x6c\x6c\x6f"

      expect { subject.utf8_diff }.not_to raise_error
    end
  end
end
