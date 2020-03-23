# frozen_string_literal: true

RSpec.shared_examples 'it uploads and commit a new text file' do
  it 'uploads and commit a new text file', :js do
    find('.add-to-tree').click
    click_link('Upload file')
    drop_in_dropzone(File.join(Rails.root, 'spec', 'fixtures', 'doc_sample.txt'))

    page.within('#modal-upload-blob') do
      fill_in(:commit_message, with: 'New commit message')
    end

    fill_in(:branch_name, with: 'upload_text', visible: true)
    click_button('Upload file')

    expect(page).to have_content('New commit message')
    expect(current_path).to eq(project_new_merge_request_path(project))

    click_link('Changes')
    find("a[data-action='diffs']", text: 'Changes').click

    wait_for_requests

    expect(page).to have_content('Lorem ipsum dolor sit amet')
    expect(page).to have_content('Sed ut perspiciatis unde omnis')
  end
end

RSpec.shared_examples 'it uploads and commit a new image file' do
  it 'uploads and commit a new image file', :js do
    find('.add-to-tree').click
    click_link('Upload file')
    drop_in_dropzone(File.join(Rails.root, 'spec', 'fixtures', 'logo_sample.svg'))

    page.within('#modal-upload-blob') do
      fill_in(:commit_message, with: 'New commit message')
      fill_in(:branch_name, with: 'upload_image', visible: true)
      click_button('Upload file')
    end

    wait_for_all_requests

    visit(project_blob_path(project, 'upload_image/logo_sample.svg'))

    expect(page).to have_css('.file-content img')
  end
end

RSpec.shared_examples 'it uploads and commit a new file to a forked project' do
  let(:fork_message) do
    "You're not allowed to make changes to this project directly. "\
    "A fork of this project has been created that you can make changes in, so you can submit a merge request."
  end

  it 'uploads and commit a new file to a forked project', :js, :sidekiq_might_not_need_inline do
    find('.add-to-tree').click
    click_link('Upload file')

    expect(page).to have_content(fork_message)

    find('.add-to-tree').click
    click_link('Upload file')
    drop_in_dropzone(File.join(Rails.root, 'spec', 'fixtures', 'doc_sample.txt'))

    page.within('#modal-upload-blob') do
      fill_in(:commit_message, with: 'New commit message')
    end

    click_button('Upload file')

    expect(page).to have_content('New commit message')

    fork = user.fork_of(project2.reload)

    expect(current_path).to eq(project_new_merge_request_path(fork))

    find("a[data-action='diffs']", text: 'Changes').click

    wait_for_requests

    expect(page).to have_content('Lorem ipsum dolor sit amet')
    expect(page).to have_content('Sed ut perspiciatis unde omnis')
  end
end
