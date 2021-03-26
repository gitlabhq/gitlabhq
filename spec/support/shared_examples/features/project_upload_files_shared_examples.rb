# frozen_string_literal: true

RSpec.shared_examples 'it uploads and commits a new text file' do
  it 'uploads and commits a new text file', :js do
    find('.add-to-tree').click

    page.within('.dropdown-menu') do
      click_link('Upload file')

      wait_for_requests
    end

    attach_file('upload_file', File.join(Rails.root, 'spec', 'fixtures', 'doc_sample.txt'), make_visible: true)

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

RSpec.shared_examples 'it uploads and commits a new image file' do
  it 'uploads and commits a new image file', :js do
    find('.add-to-tree').click

    page.within('.dropdown-menu') do
      click_link('Upload file')

      wait_for_requests
    end

    attach_file('upload_file', File.join(Rails.root, 'spec', 'fixtures', 'logo_sample.svg'), make_visible: true)

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

RSpec.shared_examples 'it uploads and commits a new pdf file' do
  it 'uploads and commits a new pdf file', :js do
    find('.add-to-tree').click

    page.within('.dropdown-menu') do
      click_link('Upload file')

      wait_for_requests
    end

    attach_file('upload_file', File.join(Rails.root, 'spec', 'fixtures', 'git-cheat-sheet.pdf'), make_visible: true)

    page.within('#modal-upload-blob') do
      fill_in(:commit_message, with: 'New commit message')
      fill_in(:branch_name, with: 'upload_image', visible: true)
      click_button('Upload file')
    end

    wait_for_all_requests

    visit(project_blob_path(project, 'upload_image/git-cheat-sheet.pdf'))

    expect(page).to have_css('.js-pdf-viewer')
  end
end

RSpec.shared_examples 'it uploads and commits a new file to a forked project' do
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
    click_link('Upload file')
    attach_file('upload_file', File.join(Rails.root, 'spec', 'fixtures', 'doc_sample.txt'), make_visible: true)

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

RSpec.shared_examples 'it uploads a file to a sub-directory' do
  it 'uploads a file to a sub-directory', :js do
    click_link 'files'

    page.within('.repo-breadcrumb') do
      expect(page).to have_content('files')
    end

    find('.add-to-tree').click
    click_link('Upload file')
    attach_file('upload_file', File.join(Rails.root, 'spec', 'fixtures', 'doc_sample.txt'), make_visible: true)

    page.within('#modal-upload-blob') do
      fill_in(:commit_message, with: 'New commit message')
    end

    click_button('Upload file')

    expect(page).to have_content('New commit message')

    page.within('.repo-breadcrumb') do
      expect(page).to have_content('files')
      expect(page).to have_content('doc_sample.txt')
    end
  end
end

RSpec.shared_examples 'uploads and commits a new text file via "upload file" button' do
  it 'uploads and commits a new text file via "upload file" button', :js do
    find('[data-testid="upload-file-button"]').click

    attach_file('upload_file', File.join(Rails.root, 'spec', 'fixtures', 'doc_sample.txt'), make_visible: true)

    page.within('#details-modal-upload-blob') do
      fill_in(:commit_message, with: 'New commit message')
    end

    click_button('Upload file')

    expect(page).to have_content('New commit message')
    expect(page).to have_content('Lorem ipsum dolor sit amet')
    expect(page).to have_content('Sed ut perspiciatis unde omnis')
  end
end
