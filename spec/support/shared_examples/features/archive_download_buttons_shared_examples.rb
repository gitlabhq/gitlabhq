# frozen_string_literal: true

shared_examples 'archive download buttons' do
  let(:formats) { %w(zip tar.gz tar.bz2 tar) }
  let(:path_to_visit) { project_path(project) }
  let(:ref) { project.default_branch }

  context 'when static objects external storage is enabled' do
    before do
      allow_any_instance_of(ApplicationSetting).to receive(:static_objects_external_storage_url).and_return('https://cdn.gitlab.com')
      visit path_to_visit
    end

    context 'private project' do
      it 'shows archive download buttons with external storage URL prepended and user token appended to their href' do
        formats.each do |format|
          path = archive_path(project, ref, format)
          uri = URI('https://cdn.gitlab.com')
          uri.path = path
          uri.query = "token=#{user.static_object_token}"

          expect(page).to have_link format, href: uri.to_s
        end
      end
    end

    context 'public project' do
      let(:project) { create(:project, :repository, :public) }

      it 'shows archive download buttons with external storage URL prepended to their href' do
        formats.each do |format|
          path = archive_path(project, ref, format)
          uri = URI('https://cdn.gitlab.com')
          uri.path = path

          expect(page).to have_link format, href: uri.to_s
        end
      end
    end
  end

  context 'when static objects external storage is disabled' do
    before do
      visit path_to_visit
    end

    it 'shows default archive download buttons' do
      formats.each do |format|
        path = archive_path(project, ref, format)

        expect(page).to have_link format, href: path
      end
    end
  end

  def archive_path(project, ref, format)
    project_archive_path(project, id: "#{ref}/#{project.path}-#{ref}", path: nil, format: format)
  end
end
