# frozen_string_literal: true

RSpec.shared_examples 'users with note access' do
  it 'returns true' do
    users.each do |user|
      expect(note.system_note_visible_for?(user)).to be_truthy
      expect(note.readable_by?(user)).to be_truthy
    end
  end
end

RSpec.shared_examples 'users without note access' do
  it 'returns false' do
    users.each do |user|
      expect(note.system_note_visible_for?(user)).to be_falsy
      expect(note.readable_by?(user)).to be_falsy
    end
  end
end
