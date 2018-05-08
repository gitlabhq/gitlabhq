shared_examples 'system note creation' do |update_params, note_text|
  subject { described_class.new(project, user).execute(issuable, [])}

  before do
    issuable.assign_attributes(update_params)
    issuable.save
  end

  it 'creates 1 system note with the correct content' do
    expect { subject }.to change { Note.count }.from(0).to(1)

    note = Note.last
    expect(note.note).to match(note_text)
    expect(note.noteable_type).to eq(issuable.class.name)
  end
end

shared_examples 'WIP notes creation' do |wip_action|
  subject { described_class.new(project, user).execute(issuable, []) }

  it 'creates WIP toggle and title change notes' do
    expect { subject }.to change { Note.count }.from(0).to(2)

    expect(Note.first.note).to match("#{wip_action} as a **Work In Progress**")
    expect(Note.second.note).to match('changed title')
  end
end
