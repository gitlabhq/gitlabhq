# frozen_string_literal: true

# Requires a context containing:
#   wiki
#   user

RSpec.shared_examples 'Wiki redirection' do
  using RSpec::Parameterized::TableSyntax

  include WikiHelpers

  let!(:parent_page) do
    create(:wiki_page, wiki: wiki, title: 'parent', content: 'Lorem ipsum')
  end

  let!(:child_page) do
    create(:wiki_page, wiki: wiki, title: 'parent/child', content: 'Lorem ipsum')
  end

  let!(:grandchild_page) do
    create(:wiki_page, wiki: wiki, title: 'parent/child/grandchild', content: 'Lorem ipsum')
  end

  before do
    sign_in(user)
    visit(wiki_path(wiki, action: :pages))
  end

  context 'when pages and directories are renamed in order from child to parent' do
    before do
      # rubocop:disable Rails/SaveBang -- Not an ActiveRecord object
      wiki.find_page('parent/child/grandchild').update(title: 'new-grandchild')
      wiki.find_page('parent/child').update(title: 'new-child')
      wiki.find_page('parent').update(title: 'new-parent')
      # rubocop:enable Rails/SaveBang
    end

    it 'updates the .gitlab/redirects.yml file with all redirects' do
      expect(wiki.repository.blob_at('master', '.gitlab/redirects.yml').data).to eq(
        <<~YML
          ---
          parent/child/grandchild: parent/child/new-grandchild
          parent/child: parent/new-child
          parent: new-parent
        YML
      )
    end

    where(:old_path, :new_path) do
      'parent'                          | 'new-parent'
      'parent/child'                    | 'new-parent/new-child'
      'parent/new-child'                | 'new-parent/new-child'
      'parent/child/grandchild'         | 'new-parent/new-child/new-grandchild'
      'parent/child/new-grandchild'     | 'new-parent/new-child/new-grandchild'
      'parent/new-child/new-grandchild' | 'new-parent/new-child/new-grandchild'
    end

    with_them do
      it 'redirects old path to new path' do
        visit wiki_page_path(wiki, old_path)

        expect(page).to have_content("The page at #{old_path} has been moved to #{new_path}.")
      end
    end

    where(:old_path, :new_path) do
      'parent/new-child/grandchild' | 'new-parent/new-child/grandchild'
    end

    with_them do
      it 'redirects old path to a create page at new path' do
        visit wiki_page_path(wiki, old_path)

        expect(page).to have_content("The page at #{old_path} tried to redirect to #{new_path}, but it does not exist.")
        expect(page).to have_content("You are now editing the page at #{new_path}. Edit page at #{old_path} instead.")
      end
    end

    where(:old_path) do
      [
        'new-parent/child',
        'new-parent/child/grandchild',
        'new-parent/new-child/grandchild',
        'new-parent/child/new-grandchild'
      ]
    end

    with_them do
      it 'does not redirect old path anywhere' do
        visit wiki_page_path(wiki, old_path)

        expect(page).not_to have_content("The page at #{old_path}")
      end
    end
  end

  context 'when pages and directories are renamed in order from parent to child' do
    before do
      # rubocop:disable Rails/SaveBang -- Not an ActiveRecord object
      wiki.find_page('parent').update(title: 'new-parent')
      wiki.find_page('new-parent/child').update(title: 'new-child')
      wiki.find_page('new-parent/new-child/grandchild').update(title: 'new-grandchild')
      # rubocop:enable Rails/SaveBang
    end

    it 'updates the .gitlab/redirects.yml file with all redirects' do
      expect(wiki.repository.blob_at('master', '.gitlab/redirects.yml').data).to eq(
        <<~YML
          ---
          parent: new-parent
          new-parent/child: new-parent/new-child
          new-parent/new-child/grandchild: new-parent/new-child/new-grandchild
        YML
      )
    end

    where(:old_path, :new_path) do
      'parent'                          | 'new-parent'
      'parent/child'                    | 'new-parent/new-child'
      'new-parent/child'                | 'new-parent/new-child'
      'parent/new-child'                | 'new-parent/new-child'
      'parent/child/grandchild'         | 'new-parent/new-child/new-grandchild'
      'new-parent/child/grandchild'     | 'new-parent/new-child/new-grandchild'
      'parent/new-child/grandchild'     | 'new-parent/new-child/new-grandchild'
      'parent/child/new-grandchild'     | 'new-parent/new-child/new-grandchild'
      'new-parent/new-child/grandchild' | 'new-parent/new-child/new-grandchild'
      'new-parent/child/new-grandchild' | 'new-parent/new-child/new-grandchild'
      'parent/new-child/new-grandchild' | 'new-parent/new-child/new-grandchild'
    end

    with_them do
      it 'redirects old path to new path' do
        visit wiki_page_path(wiki, old_path)

        expect(page).to have_content("The page at #{old_path} has been moved to #{new_path}.")
      end
    end
  end
end
