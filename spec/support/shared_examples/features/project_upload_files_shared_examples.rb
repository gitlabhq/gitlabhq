# frozen_string_literal: true

RSpec.shared_examples 'it uploads and commits a new text file' do |drop: false|
  it 'uploads and commits a new text file', :js do
    find('.add-to-tree').click

    page.within('.repo-breadcrumb') do
      click_button('Upload file')

      wait_for_requests
    end

    if drop
      find(".upload-dropzone-card").drop(File.join(Rails.root, 'spec', 'fixtures', 'doc_sample.txt'))
    else
      attach_file('upload_file', File.join(Rails.root, 'spec', 'fixtures', 'doc_sample.txt'), make_visible: true)
    end

    page.within('#modal-upload-blob') do
      fill_in(:commit_message, with: 'New commit message')
      choose(option: true)
      fill_in(:branch_name, with: 'upload_text', visible: true)
      click_button('Commit changes')
    end

    expect(page).to have_content('New commit message')
    expect(page).to have_current_path(project_new_merge_request_path(project), ignore_query: true)

    click_link('Changes')
    find("a[data-action='diffs']", text: 'Changes').click

    wait_for_requests

    expect(page).to have_content('Lorem ipsum dolor sit amet')
    expect(page).to have_content('Sed ut perspiciatis unde omnis')
  end
end

RSpec.shared_examples 'it uploads and commits a new image file' do |drop: false|
  it 'uploads and commits a new image file', :js do
    find('.add-to-tree').click

    page.within('.repo-breadcrumb') do
      click_button('Upload file')

      wait_for_requests
    end

    if drop
      find(".upload-dropzone-card").drop(File.join(Rails.root, 'spec', 'fixtures', 'logo_sample.svg'))
    else
      attach_file('upload_file', File.join(Rails.root, 'spec', 'fixtures', 'logo_sample.svg'), make_visible: true)
    end

    page.within('#modal-upload-blob') do
      fill_in(:commit_message, with: 'New commit message')
      choose(option: true)
      fill_in(:branch_name, with: 'upload_image', visible: true)
      click_button('Commit changes')
    end

    wait_for_all_requests

    visit(project_blob_path(project, 'upload_image/logo_sample.svg'))

    expect(page).to have_css('.file-holder img')
  end
end

RSpec.shared_examples 'it uploads and commits a new pdf file' do |drop: false|
  it 'uploads and commits a new pdf file', :js do
    find('.add-to-tree').click

    page.within('.repo-breadcrumb') do
      click_button('Upload file')

      wait_for_requests
    end

    if drop
      find(".upload-dropzone-card").drop(File.join(Rails.root, 'spec', 'fixtures', 'sample.pdf'))
    else
      attach_file('upload_file', File.join(Rails.root, 'spec', 'fixtures', 'sample.pdf'), make_visible: true)
    end

    page.within('#modal-upload-blob') do
      fill_in(:commit_message, with: 'New commit message')
      choose(option: true)
      fill_in(:branch_name, with: 'upload_image', visible: true)
      click_button('Commit changes')
    end

    wait_for_all_requests

    visit(project_blob_path(project, 'upload_image/sample.pdf'))

    wait_for_all_requests

    expect(page).to have_css('.js-pdf-viewer')
    expect(page).not_to have_content('An error occurred while loading the file. Please try again later.')
  end
end

RSpec.shared_examples 'it uploads and commits a new file to a forked project' do |drop: false|
  let(:fork_message) do
    "You're not allowed to make changes to this project directly. "\
    "A fork of this project has been created that you can make changes in, so you can submit a merge request."
  end

  it 'uploads and commits a new file to a forked project', :js, :sidekiq_might_not_need_inline do
    find('.add-to-tree').click
    click_link('Upload file')

    expect(page).to have_content(fork_message)

    wait_for_all_requests

    find('.add-to-tree').click
    click_button('Upload file')

    if drop
      find(".upload-dropzone-card").drop(File.join(Rails.root, 'spec', 'fixtures', 'doc_sample.txt'))
    else
      attach_file('upload_file', File.join(Rails.root, 'spec', 'fixtures', 'doc_sample.txt'), make_visible: true)
    end

    page.within('#modal-upload-blob') do
      fill_in(:commit_message, with: 'New commit message')
      click_button('Commit changes')
    end

    expect(page).to have_content('New commit message')

    fork = user.fork_of(project2.reload)

    expect(page).to have_current_path(project_new_merge_request_path(fork), ignore_query: true)

    find("a[data-action='diffs']", text: 'Changes').click

    wait_for_requests

    expect(page).to have_content('Lorem ipsum dolor sit amet')
    expect(page).to have_content('Sed ut perspiciatis unde omnis')
  end
end

RSpec.shared_examples 'it uploads a file to a sub-directory' do |drop: false|
  it 'uploads a file to a sub-directory', :js do
    click_link 'files'

    page.within('.repo-breadcrumb') do
      expect(page).to have_content('files')
    end

    find('.add-to-tree').click
    click_button('Upload file')

    if drop
      find(".upload-dropzone-card").drop(File.join(Rails.root, 'spec', 'fixtures', 'doc_sample.txt'))
    else
      attach_file('upload_file', File.join(Rails.root, 'spec', 'fixtures', 'doc_sample.txt'), make_visible: true)
    end

    page.within('#modal-upload-blob') do
      fill_in(:commit_message, with: 'New commit message')
      click_button('Commit changes')
    end

    expect(page).to have_content('New commit message')

    page.within('.repo-breadcrumb') do
      expect(page).to have_content('files')
      expect(page).to have_content('doc_sample.txt')
    end
  end
end

RSpec.shared_examples 'uploads and commits a new text file via "upload file" button' do |drop: false|
  it 'uploads and commits a new text file via "upload file" button', :js do
    find('[data-testid="upload-file-button"]').click

    if drop
      find(".upload-dropzone-card").drop(File.join(Rails.root, 'spec', 'fixtures', 'doc_sample.txt'))
    else
      attach_file('upload_file', File.join(Rails.root, 'spec', 'fixtures', 'doc_sample.txt'), make_visible: true)
    end

    page.within('#details-modal-upload-blob') do
      fill_in(:commit_message, with: 'New commit message')
      click_button('Commit changes')
    end

    expect(page).to have_content('New commit message')
    expect(page).to have_content('Lorem ipsum dolor sit amet')
    expect(page).to have_content('Sed ut perspiciatis unde omnis')
  end
end
