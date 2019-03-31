# frozen_string_literal: true

shared_examples 'due quick action not available' do
  it 'does not set the due date' do
    add_note('/due 2016-08-28')

    expect(page).not_to have_content 'Commands applied'
    expect(page).not_to have_content '/due 2016-08-28'
  end
end

shared_examples 'due quick action available and date can be added' do
  it 'sets the due date accordingly' do
    add_note('/due 2016-08-28')

    expect(page).not_to have_content '/due 2016-08-28'
    expect(page).to have_content 'Commands applied'

    visit project_issue_path(project, issue)

    page.within '.due_date' do
      expect(page).to have_content 'Aug 28, 2016'
    end
  end
end
