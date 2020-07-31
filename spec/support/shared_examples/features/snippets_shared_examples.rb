# frozen_string_literal: true

# These shared examples expect a `snippets` array of snippets
RSpec.shared_examples 'paginated snippets' do |remote: false|
  it "is limited to #{Snippet.default_per_page} items per page" do
    expect(page.all('.snippets-list-holder .snippet-row').count).to eq(Snippet.default_per_page)
  end

  context 'clicking on the link to the second page' do
    before do
      click_link('2')
      wait_for_requests if remote
    end

    it 'shows the remaining snippets' do
      remaining_snippets_count = [snippets.size - Snippet.default_per_page, Snippet.default_per_page].min
      expect(page).to have_selector('.snippets-list-holder .snippet-row', count: remaining_snippets_count)
    end
  end
end

RSpec.shared_examples 'tabs with counts' do
  let(:tabs) { page.all('.snippet-scope-menu li') }

  it 'shows a tab for All snippets and count' do
    tab = tabs[0]

    expect(tab.text).to include('All')
    expect(tab.find('.badge').text).to eq(counts[:all])
  end

  it 'shows a tab for Private snippets and count' do
    tab = tabs[1]

    expect(tab.text).to include('Private')
    expect(tab.find('.badge').text).to eq(counts[:private])
  end

  it 'shows a tab for Internal snippets and count' do
    tab = tabs[2]

    expect(tab.text).to include('Internal')
    expect(tab.find('.badge').text).to eq(counts[:internal])
  end

  it 'shows a tab for Public snippets and count' do
    tab = tabs[3]

    expect(tab.text).to include('Public')
    expect(tab.find('.badge').text).to eq(counts[:public])
  end
end

RSpec.shared_examples 'does not show New Snippet button' do
  let(:user) { create(:user, :external) }

  specify do
    sign_in(user)

    subject

    wait_for_requests

    expect(page).not_to have_link('New snippet')
  end
end

RSpec.shared_examples 'show and render proper snippet blob' do
  before do
    allow_any_instance_of(Snippet).to receive(:blobs).and_return([snippet.repository.blob_at('master', file_path)])
  end

  context 'Ruby file' do
    let(:file_path) { 'files/ruby/popen.rb' }

    it 'displays the blob' do
      subject

      aggregate_failures do
        # shows highlighted Ruby code
        expect(page).to have_content("require 'fileutils'")

        # does not show a viewer switcher
        expect(page).not_to have_selector('.js-blob-viewer-switcher')

        # shows an enabled copy button
        expect(page).to have_selector('.js-copy-blob-source-btn:not(.disabled)')

        # shows a raw button
        expect(page).to have_link('Open raw')

        # shows a download button
        expect(page).to have_link('Download')
      end
    end
  end

  context 'Markdown file' do
    let(:file_path) { 'files/markdown/ruby-style-guide.md' }

    context 'visiting directly' do
      before do
        subject
      end

      it 'displays the blob using the rich viewer' do
        aggregate_failures do
          # hides the simple viewer
          expect(page).to have_selector('.blob-viewer[data-type="simple"]', visible: false)
          expect(page).to have_selector('.blob-viewer[data-type="rich"]')

          # shows rendered Markdown
          expect(page).to have_link("PEP-8")

          # shows a viewer switcher
          expect(page).to have_selector('.js-blob-viewer-switcher')

          # shows a disabled copy button
          expect(page).to have_selector('.js-copy-blob-source-btn.disabled')

          # shows a raw button
          expect(page).to have_link('Open raw')

          # shows a download button
          expect(page).to have_link('Download')
        end
      end

      context 'switching to the simple viewer' do
        before do
          find('.js-blob-viewer-switch-btn[data-viewer=simple]').click

          wait_for_requests
        end

        it 'displays the blob using the simple viewer' do
          aggregate_failures do
            # hides the rich viewer
            expect(page).to have_selector('.blob-viewer[data-type="simple"]')
            expect(page).to have_selector('.blob-viewer[data-type="rich"]', visible: false)

            # shows highlighted Markdown code
            expect(page).to have_content("[PEP-8](http://www.python.org/dev/peps/pep-0008/)")

            # shows an enabled copy button
            expect(page).to have_selector('.js-copy-blob-source-btn:not(.disabled)')
          end
        end

        context 'switching to the rich viewer again' do
          before do
            find('.js-blob-viewer-switch-btn[data-viewer=rich]').click

            wait_for_requests
          end

          it 'displays the blob using the rich viewer' do
            aggregate_failures do
              # hides the simple viewer
              expect(page).to have_selector('.blob-viewer[data-type="simple"]', visible: false)
              expect(page).to have_selector('.blob-viewer[data-type="rich"]')

              # shows an enabled copy button
              expect(page).to have_selector('.js-copy-blob-source-btn:not(.disabled)')
            end
          end
        end
      end
    end

    context 'visiting with a line number anchor' do
      let(:anchor) { 'L1' }

      it 'displays the blob using the simple viewer' do
        subject

        aggregate_failures do
          # hides the rich viewer
          expect(page).to have_selector('.blob-viewer[data-type="simple"]')
          expect(page).to have_selector('.blob-viewer[data-type="rich"]', visible: false)

          # highlights the line in question
          expect(page).to have_selector('#LC1.hll')

          # shows highlighted Markdown code
          expect(page).to have_content("[PEP-8](http://www.python.org/dev/peps/pep-0008/)")

          # shows an enabled copy button
          expect(page).to have_selector('.js-copy-blob-source-btn:not(.disabled)')
        end
      end
    end
  end
end
