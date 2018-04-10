RSpec.shared_examples 'an editable merge request' do
  let(:user)        { create(:user) }
  let(:user2)       { create(:user) }
  let!(:milestone)   { create(:milestone, project: target_project) }
  let!(:label)       { create(:label, project: target_project) }
  let!(:label2)      { create(:label, project: target_project) }
  let(:target_project) { create(:project, :public, :repository) }
  let(:source_project) { target_project }
  let(:merge_request) do
    create(:merge_request,
      source_project: source_project,
      target_project: target_project,
      source_branch: 'fix',
      target_branch: 'master')
  end

  before do
    source_project.add_master(user)
    target_project.add_master(user)
    target_project.add_master(user2)

    sign_in(user)
    visit edit_project_merge_request_path(target_project, merge_request)
  end

  it 'updates merge request', :js do
    click_button 'Assignee'
    page.within '.dropdown-menu-user' do
      click_link user.name
    end
    expect(find('input[name="merge_request[assignee_id]"]', visible: false).value).to match(user.id.to_s)
    page.within '.js-assignee-search' do
      expect(page).to have_content user.name
    end

    click_button 'Milestone'
    page.within '.issue-milestone' do
      click_link milestone.title
    end
    expect(find('input[name="merge_request[milestone_id]"]', visible: false).value).to match(milestone.id.to_s)
    page.within '.js-milestone-select' do
      expect(page).to have_content milestone.title
    end

    click_button 'Labels'
    page.within '.dropdown-menu-labels' do
      click_link label.title
      click_link label2.title
    end
    expect(page.all('input[name="merge_request[label_ids][]"]', visible: false)[1].value).to match(label.id.to_s)
    expect(page.all('input[name="merge_request[label_ids][]"]', visible: false)[2].value).to match(label2.id.to_s)
    page.within '.js-label-select' do
      expect(page).to have_content label.title
    end

    click_button 'Save changes'

    page.within '.issuable-sidebar' do
      page.within '.assignee' do
        expect(page).to have_content user.name
      end

      page.within '.milestone' do
        expect(page).to have_content milestone.title
      end

      page.within '.labels' do
        expect(page).to have_content label.title
        expect(page).to have_content label2.title
      end
    end
  end

  it 'description has autocomplete', :js do
    find('#merge_request_description').native.send_keys('')
    fill_in 'merge_request_description', with: '@'

    expect(page).to have_selector('.atwho-view')
  end

  it 'has class js-quick-submit in form' do
    expect(page).to have_selector('.js-quick-submit')
  end

  it 'warns about version conflict' do
    merge_request.update(title: "New title")

    fill_in 'merge_request_title', with: 'bug 345'
    fill_in 'merge_request_description', with: 'bug description'

    click_button 'Save changes'

    expect(page).to have_content 'Someone edited the merge request the same time you did'
  end

  it 'preserves description textarea height', :js do
    long_description = %q(
    Lorem ipsum dolor sit amet, consectetur adipiscing elit. Etiam ac ornare ligula, ut tempus arcu. Etiam ultricies accumsan dolor vitae faucibus. Donec at elit lacus. Mauris orci ante, aliquam quis lorem eget, convallis faucibus arcu. Aenean at pulvinar lacus. Ut viverra quam massa, molestie ornare tortor dignissim a. Suspendisse tristique pellentesque tellus, id lacinia metus elementum id. Nam tristique, arcu rhoncus faucibus viverra, lacus ipsum sagittis ligula, vitae convallis odio lacus a nibh. Ut tincidunt est purus, ac vestibulum augue maximus in. Suspendisse vel erat et mi ultricies semper. Pellentesque volutpat pellentesque consequat.

    Cras congue nec ligula tristique viverra. Curabitur fringilla fringilla fringilla. Donec rhoncus dignissim orci ut accumsan. Ut rutrum urna a rhoncus varius. Maecenas blandit, mauris nec accumsan gravida, augue nibh finibus magna, sed maximus turpis libero nec neque. Suspendisse at semper est. Nunc imperdiet dapibus dui, varius sollicitudin erat luctus non. Sed pellentesque ligula eget posuere facilisis. Donec dictum commodo volutpat. Donec egestas dui ac magna sollicitudin bibendum. Vivamus purus neque, ullamcorper ac feugiat et, tempus sit amet metus. Praesent quis viverra neque. Sed bibendum viverra est, eu aliquam mi ornare vitae. Proin et dapibus ipsum. Nunc tortor diam, malesuada nec interdum vel, placerat quis justo. Ut viverra at erat eu laoreet.

    Pellentesque commodo, diam sit amet dignissim condimentum, tortor justo pretium est, non venenatis metus eros ut nunc. Etiam ut neque eget sem dapibus aliquam. Curabitur vel elit lorem. Nulla nec enim elit. Sed ut ex id justo facilisis convallis at ac augue. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Nullam cursus egestas turpis non tristique. Suspendisse in erat sem. Fusce libero elit, fermentum gravida mauris id, auctor iaculis felis. Nullam vulputate tempor laoreet.

    Nam tempor et magna sed convallis. Fusce sit amet sollicitudin risus, a ullamcorper lacus. Morbi gravida quis sem eget porttitor. Donec eu egestas mauris, in elementum tortor. Sed eget ex mi. Mauris iaculis tortor ut est auctor, nec dignissim quam sagittis. Suspendisse vel metus non quam suscipit tincidunt. Cras molestie lacus non justo finibus sodales quis vitae erat. In a porttitor nisi, id sollicitudin urna. Ut at felis tellus. Suspendisse potenti.

    Maecenas leo ligula, varius at neque vitae, ornare maximus justo. Nullam convallis luctus risus et vulputate. Duis suscipit faucibus iaculis. Etiam quis tortor faucibus, tristique tellus sit amet, sodales neque. Nulla dapibus nisi vel aliquet consequat. Etiam faucibus, metus eget condimentum iaculis, enim urna lobortis sem, id efficitur eros sapien nec nisi. Aenean ut finibus ex.
    )

    fill_in 'merge_request_description', with: long_description

    height = get_textarea_height
    find('.js-md-preview-button').click
    find('.js-md-write-button').click
    new_height = get_textarea_height

    expect(height).to eq(new_height)
  end

  context 'when "Remove source branch" is set' do
    before do
      merge_request.update!(merge_params: { 'force_remove_source_branch' => '1' })
    end

    it 'allows to unselect "Remove source branch"', :js do
      expect(merge_request.merge_params['force_remove_source_branch']).to be_truthy

      visit edit_project_merge_request_path(target_project, merge_request)
      uncheck 'Remove source branch when merge request is accepted'

      click_button 'Save changes'

      expect(page).to have_unchecked_field 'remove-source-branch-input'
      expect(page).to have_content 'Remove source branch'
    end
  end
end

def get_textarea_height
  page.evaluate_script('document.getElementById("merge_request_description").offsetHeight')
end
