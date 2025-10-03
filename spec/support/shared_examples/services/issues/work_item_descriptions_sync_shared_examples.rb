# frozen_string_literal: true

RSpec.shared_examples 'syncs successfully to work_item_description' do
  it 'syncs the data from the issue to the work_item_description record' do
    subject

    description_record = issue.work_item_description

    expect(description_record.reload.description).to eq(issue.reload.description)
    expect(description_record.description_html).to eq(issue.description_html)
    expect(description_record.last_editing_user).to eq(issue.last_edited_by)
    expect(description_record.last_edited_at).to eq(issue.last_edited_at)
    expect(description_record.lock_version).to eq(issue.lock_version)
    expect(description_record.cached_markdown_version).to eq(issue.cached_markdown_version)
  end
end
