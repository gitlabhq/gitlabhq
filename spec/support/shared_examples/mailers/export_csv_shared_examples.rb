# frozen_string_literal: true

RSpec.shared_examples 'export csv email' do |collection_type|
  include_context 'gitlab email notification'

  it 'attachment has csv mime type' do
    expect(attachment.mime_type).to eq 'text/csv'
  end

  it 'generates a useful filename' do
    expect(attachment.filename).to include(Date.today.year.to_s)
    expect(attachment.filename).to include(collection_type)
    expect(attachment.filename).to include('myproject')
    expect(attachment.filename).to end_with('.csv')
  end

  it 'mentions number of objects and project name' do
    expect(subject).to have_content '3'
    expect(subject).to have_content empty_project.name
  end

  it "doesn't need to mention truncation by default" do
    expect(subject).not_to have_content 'truncated'
  end

  context 'when truncated' do
    let(:export_status) { { truncated: true, rows_expected: 12, rows_written: 10 } }

    it 'mentions that the csv has been truncated' do
      expect(subject).to have_content 'truncated'
    end

    it 'mentions the number of objects written and expected' do
      expect(subject).to have_content "10 of 12 #{collection_type.humanize.downcase}"
    end
  end
end
