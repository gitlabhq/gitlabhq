# frozen_string_literal: true

RSpec.shared_examples 'archive download buttons' do
  let(:path_to_visit) { project_path(project) }
  let(:ref) { project.default_branch }
  let(:ref_type) { 'heads' }
  let(:button_test_id) { 'download-source-code-button' }
  let(:download_button_container) { nil }

  context 'when static objects external storage is enabled' do
    before do
      allow_any_instance_of(ApplicationSetting).to receive(:static_objects_external_storage_url).and_return('https://cdn.gitlab.com')
      visit path_to_visit
    end

    context 'private project', :js do
      it 'shows archive download buttons with external storage URL prepended and user token appended to their href' do
        click_download_button

        Gitlab::Workhorse::ARCHIVE_FORMATS.each do |format|
          parsed_path = archive_path(project, ref, ref_type, format)
          uri = cdn_path(parsed_path, token: user.static_object_token)

          expect(page).to have_link format, href: uri.to_s
        end
      end
    end

    context 'public project', :js do
      let(:project) { create(:project, :repository, :public) }

      it 'shows archive download buttons with external storage URL prepended to their href' do
        click_download_button

        Gitlab::Workhorse::ARCHIVE_FORMATS.each do |format|
          parsed_path = archive_path(project, ref, ref_type, format)
          uri = cdn_path(parsed_path)

          expect(page).to have_link format, href: uri.to_s
        end
      end
    end
  end

  context 'when static objects external storage is disabled', :js do
    before do
      visit path_to_visit
    end

    it 'shows default archive download buttons' do
      click_download_button

      Gitlab::Workhorse::ARCHIVE_FORMATS.each do |format|
        parsed_path = archive_path(project, ref, ref_type, format)

        expect(page).to have_link format, href: parsed_path.to_s
      end
    end
  end

  def click_download_button
    if download_button_container
      within(download_button_container) { find_by_testid(button_test_id).click }
    else
      find_by_testid(button_test_id).click
    end
  end

  def cdn_path(original_path, token: nil)
    uri = URI('https://cdn.gitlab.com')
    uri.path = original_path.path

    query = Rack::Utils.parse_nested_query(original_path.query)
    query['token'] = user.static_object_token if token
    uri.query = query.to_query

    uri
  end

  def archive_path(project, ref, ref_type, format)
    URI(project_archive_path(project, id: "#{ref}/#{project.path}-#{ref}", path: nil, ref_type: ref_type,
      format: format))
  end
end
