# frozen_string_literal: true

RSpec.shared_examples 'system note creation' do |update_params, note_text, is_update = true|
  subject do
    described_class.new(project: project, current_user: user).execute(issuable, old_labels: [], is_update: is_update)
  end

  before do
    issuable.assign_attributes(update_params)
    issuable.save!
  end

  it 'creates 1 system note with the correct content' do
    expect { subject }.to change { Note.count }.from(0).to(1)

    note = Note.last
    expect(note.note).to match(note_text)
    expect(note.noteable_type).to eq(issuable.class.name)
  end
end

RSpec.shared_examples 'draft notes creation' do |action|
  subject { described_class.new(project: project, current_user: user).execute(issuable, old_labels: []) }

  it 'creates Draft toggle and title change notes' do
    expect { subject }.to change { Note.count }.from(0).to(2)

    expect(Note.first.note).to match("marked this merge request as **#{action}**")
    expect(Note.second.note).to match('changed title')
  end
end

RSpec.shared_examples 'a note with overridable created_at' do
  let(:noteable) { create(:issue, project: project, system_note_timestamp: Time.at(42)) }

  it 'the note has the correct time' do
    expect(subject.created_at).to eq Time.at(42)
  end
end

RSpec.shared_examples 'a system note' do |params|
  let(:expected_noteable) { noteable }
  let(:commit_count)      { nil }

  it 'has the correct attributes', :aggregate_failures do
    exclude_project = !params.nil? && params[:exclude_project]
    skip_persistence_check = !params.nil? && params[:skip_persistence_check]

    expect(subject).to be_valid
    expect(subject).to be_system

    expect(subject.noteable).to eq expected_noteable
    expect(subject.project).to eq project unless exclude_project
    expect(subject.author).to eq author

    expect(subject.system_note_metadata).to be_persisted unless skip_persistence_check
    expect(subject.system_note_metadata.action).to eq(action)
    expect(subject.system_note_metadata.commit_count).to eq(commit_count)
  end
end
