# frozen_string_literal: true

RSpec.shared_examples 'autocompletes items' do
  before do
    if defined?(project)
      create(:issue, project: project, title: 'My Cool Linked Issue')
      create(:merge_request, source_project: project, title: 'My Cool Merge Request')
      create(:label, project: project, title: 'My Cool Label')
      create(:milestone, project: project, title: 'My Cool Milestone')

      project.add_maintainer(create(:user, name: 'JohnDoe123'))
    else # group wikis
      project = create(:project, group: group)

      create(:issue, project: project, title: 'My Cool Linked Issue')
      create(:merge_request, source_project: project, title: 'My Cool Merge Request')
      create(:group_label, group: group, title: 'My Cool Label')
      create(:milestone, group: group, title: 'My Cool Milestone')

      project.add_maintainer(create(:user, name: 'JohnDoe123'))
    end
  end

  it 'works well for issues, labels, MRs, members, etc' do
    fill_in :wiki_content, with: "#"
    expect(page).to have_text 'My Cool Linked Issue'

    fill_in :wiki_content, with: "~"
    expect(page).to have_text 'My Cool Label'

    fill_in :wiki_content, with: "!"
    expect(page).to have_text 'My Cool Merge Request'

    fill_in :wiki_content, with: "%"
    expect(page).to have_text 'My Cool Milestone'

    fill_in :wiki_content, with: "@"
    expect(page).to have_text 'JohnDoe123'

    fill_in :wiki_content, with: ':smil'
    expect(page).to have_text 'smile_cat'
  end
end
