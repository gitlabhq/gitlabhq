# frozen_string_literal: true

RSpec.shared_examples 'uploads actions' do
  describe "GET #show" do
    context 'with file traversal in filename parameter' do
      # Uploads in tests are stored in directories like:
      # tmp/tests/public/uploads/@hashed/AB/CD/ABCD/SECRET
      let(:filename) { "../../../../../../../../../Gemfile.lock" }
      let(:escaped_filename) { CGI.escape filename }

      it 'responds with status 400' do
        # Check files do indeed exists
        upload_absolute_path = Pathname(upload.absolute_path)
        expect(upload_absolute_path).to be_exist
        attacked_file_path = upload_absolute_path.dirname.join(filename)
        expect(attacked_file_path).to be_exist

        # Need to escape, otherwise we get `ActionController::UrlGenerationError Exception: No route matches`
        get show_path.sub(File.basename(upload.path), escaped_filename)

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end
  end
end
