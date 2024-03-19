# frozen_string_literal: true

RSpec.shared_examples 'archive download buttons' do
  let(:path_to_visit) { project_path(project) }
  let(:ref) { project.default_branch }

  context 'when static objects external storage is enabled' do
    before do
      allow_any_instance_of(ApplicationSetting).to receive(:static_objects_external_storage_url).and_return('https://cdn.gitlab.com')
      visit path_to_visit
    end

    context 'private project', :js do
      it 'shows archive download buttons with external storage URL prepended and user token appended to their href' do
        Gitlab::Workhorse::ARCHIVE_FORMATS.each do |format|
          path = archive_path(project, ref, format)
          uri = URI('https://cdn.gitlab.com')
          uri.path = path
          uri.query = "token=#{user.static_object_token}"

          all('[data-testid="download-source-code-button"]').first do
            find_by_testid('base-dropdown-toggle').click
            expect(page).to have_link format, href: uri.to_s
          end
        end
      end
    end

    context 'public project', :js do
      let(:project) { create(:project, :repository, :public) }

      it 'shows archive download buttons with external storage URL prepended to their href', :js do
        Gitlab::Workhorse::ARCHIVE_FORMATS.each do |format|
          path = archive_path(project, ref, format)
          uri = URI('https://cdn.gitlab.com')
          uri.path = path

          all('[data-testid="download-source-code-button"]').first do
            find_by_testid('base-dropdown-toggle').click
            expect(page).to have_link format, href: uri.to_s
          end
        end
      end
    end
  end

  context 'when static objects external storage is disabled', :js do
    before do
      visit path_to_visit
    end

    it 'shows default archive download buttons', :js do
      Gitlab::Workhorse::ARCHIVE_FORMATS.each do |format|
        path = archive_path(project, ref, format)

        all('[data-testid="download-source-code-button"]').first do
          find_by_testid('base-dropdown-toggle').click
          expect(page).to have_link format, href: path
        end
      end
    end
  end

  def archive_path(project, ref, format)
    project_archive_path(project, id: "#{ref}/#{project.path}-#{ref}", path: nil, format: format)
  end
end
