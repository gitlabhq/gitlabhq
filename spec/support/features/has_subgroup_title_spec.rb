shared_examples 'has subgroup title' do |parent_group_name, subgroup_name, project_name|
  it 'should show the full title' do
    title = find('.title-container')

    expect(title).not_to have_selector '.initializing'
    expect(title).to have_content "#{parent_group_name} / #{subgroup_name} / #{project_name}"
  end
end
