# frozen_string_literal: true

# These shared examples expect a `snippets` array of snippets
RSpec.shared_examples 'paginated snippets' do |remote: false|
  it "is limited to #{Snippet.default_per_page} items per page" do
    expect(page.all('[data-testid="snippet-link"]').count).to eq(Snippet.default_per_page)
  end

  context 'clicking on the link to the second page' do
    before do
      click_link('2')
      wait_for_requests if remote
    end

    it 'shows the remaining snippets' do
      remaining_snippets_count = [snippets.size - Snippet.default_per_page, Snippet.default_per_page].min
      expect(page).to have_css('[data-testid="snippet-link"]', count: remaining_snippets_count)
    end
  end
end

RSpec.shared_examples 'tabs with counts' do
  let(:tabs) { page.all('.js-snippets-nav-tabs li') }

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
  specify do
    expect(page).to have_link(text: "$#{snippet.id}")
    expect(page).not_to have_link('New snippet')
  end
end

RSpec.shared_examples 'does show New Snippet button' do
  specify do
    find_by_testid('snippets-more-actions-dropdown-toggle').click

    expect(page).to have_link(text: "$#{snippet.id}")
    expect(page).to have_selector('[data-testid="snippets-more-actions-dropdown"]')
    expect(page).to have_link('New snippet')
  end
end

RSpec.shared_examples 'show and render proper snippet blob' do
  context 'Ruby file' do
    let(:file_path) { 'files/ruby/popen.rb' }

    it 'displays the blob' do
      aggregate_failures do
        # shows highlighted Ruby code
        expect(page).to have_content("require 'fileutils'")

        # does not show a viewer switcher
        expect(page).not_to have_selector('.js-blob-viewer-switcher')

        # shows an enabled copy button
        expect(page).to have_button('Copy file contents', disabled: false)

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
      it 'displays the blob using the rich viewer' do
        aggregate_failures do
          # hides the simple viewer
          expect(page).to have_selector('.blob-viewer[data-type="rich"]')

          # shows rendered Markdown
          expect(page).to have_link("PEP-8")

          # shows a viewer switcher
          expect(page).to have_selector('.js-blob-viewer-switcher')

          # shows a disabled copy button
          expect(page).to have_button('Copy file contents', disabled: true)

          # shows a raw button
          expect(page).to have_link('Open raw')

          # shows a download button
          expect(page).to have_link('Download')
        end
      end

      context 'switching to the simple viewer' do
        before do
          find_button('Display source').click

          wait_for_requests
        end

        it 'displays the blob using the simple viewer' do
          aggregate_failures do
            # hides the rich viewer
            expect(page).to have_selector('.blob-viewer[data-type="simple"]')

            # shows highlighted Markdown code
            expect(page).to have_content("[PEP-8](http://www.python.org/dev/peps/pep-0008/)")

            # shows an enabled copy button
            expect(page).to have_button('Copy file contents', disabled: false)
          end
        end

        context 'switching to the rich viewer again' do
          before do
            find_button('Display rendered file').click

            wait_for_requests
          end

          it 'displays the blob using the rich viewer' do
            aggregate_failures do
              # hides the simple viewer
              expect(page).to have_selector('.blob-viewer[data-type="rich"]')

              # Used to show an enabled copy button since the code has already been fetched
              # Will be resolved in https://gitlab.com/gitlab-org/gitlab/-/issues/262389
              expect(page).to have_button('Copy file contents', disabled: true)
            end
          end
        end
      end
    end

    context 'visiting with a line number anchor' do
      # L1 used to work and will be revisited in https://gitlab.com/gitlab-org/gitlab/-/issues/262391
      let(:anchor) { 'LC1' }

      it 'displays the blob using the simple viewer' do
        aggregate_failures do
          # hides the rich viewer
          expect(page).to have_selector('.blob-viewer[data-type="simple"]')

          # highlights the line in question
          expect(page).to have_selector('#LC1.hll')

          # shows highlighted Markdown code
          expect(page).to have_content("[PEP-8](http://www.python.org/dev/peps/pep-0008/)")

          # shows an enabled copy button
          expect(page).to have_button('Copy file contents', disabled: false)
        end
      end
    end
  end
end

RSpec.shared_examples 'personal snippet with references' do
  let_it_be(:project)         { create(:project, :repository) }
  let_it_be(:merge_request)   { create(:merge_request, source_project: project) }
  let_it_be(:project_snippet) { create(:project_snippet, :repository, project: project) }
  let_it_be(:issue)           { create(:issue, project: project) }
  let_it_be(:commit)          { project.commit }

  let(:mr_reference)          { merge_request.to_reference(full: true) }
  let(:issue_reference)       { issue.to_reference(full: true) }
  let(:snippet_reference)     { project_snippet.to_reference(full: true) }
  let(:commit_reference)      { commit.reference_link_text(full: true) }

  RSpec.shared_examples 'handles resource links' do
    context 'with access to the resource' do
      before do
        project.add_developer(user)
      end

      it 'converts the reference to a link' do
        subject

        page.within(container) do
          aggregate_failures do
            expect(page).to have_link(mr_reference)
            expect(page).to have_link(issue_reference)
            expect(page).to have_link(snippet_reference)
            expect(page).to have_link(commit_reference)
          end
        end
      end
    end

    context 'without access to the resource' do
      it 'does not convert the reference to a link' do
        subject

        page.within(container) do
          expect(page).not_to have_link(mr_reference)
          expect(page).not_to have_link(issue_reference)
          expect(page).not_to have_link(snippet_reference)
          expect(page).not_to have_link(commit_reference)
        end
      end
    end
  end

  context 'when using references to resources' do
    let(:references) do
      <<~REFERENCES
        MR: #{mr_reference}

        Commit: #{commit_reference}

        Issue: #{issue_reference}

        ProjectSnippet: #{snippet_reference}
      REFERENCES
    end

    it_behaves_like 'handles resource links'
  end

  context 'when using links to resources' do
    let(:args) { { host: Gitlab.config.gitlab.url, port: nil } }
    let(:references) do
      <<~REFERENCES
        MR: #{merge_request_url(merge_request, args)}

        Commit: #{project_commit_url(project, commit, args)}

        Issue: #{issue_url(issue, args)}

        ProjectSnippet: #{project_snippet_url(project, project_snippet, args)}
      REFERENCES
    end

    it_behaves_like 'handles resource links'
  end
end
