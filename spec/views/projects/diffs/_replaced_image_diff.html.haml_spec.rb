# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/diffs/_replaced_image_diff.html.haml', feature_category: :code_review_workflow do
  # rubocop:disable RSpec/FactoryBot/AvoidCreate -- the partial renders Gitaly-backed diffs, so the repository must be persisted
  let_it_be(:project) { create(:project, :repository) }
  # rubocop:enable RSpec/FactoryBot/AvoidCreate
  let(:commit) { project.commit('570e7b2abdd848b95f2f578043fc23bd6f6fd24d') }
  let(:diff_file) { commit.diffs.diff_file_with_new_path('files/ruby/popen.rb') }
  let(:image_point) { Gitlab::Diff::ImagePoint.new(nil, nil, nil, nil) }
  let(:placeholder) { LazyImageTagHelper.placeholder_image }
  let(:rendered_image_srcs) { Nokogiri::HTML.fragment(rendered).css('img').map { |img| img['src'] } }

  before do
    assign(:project, project)
  end

  def render_view
    render partial: 'projects/diffs/replaced_image_diff', locals: {
      diff_file: diff_file,
      position: diff_file.position(image_point, position_type: :image).to_json
    }
  end

  it 'renders both sides with their raw blob URLs' do
    render_view

    expect(rendered).to have_css("img[src*='/raw/#{diff_file.content_sha}/files/ruby/popen.rb']")
    expect(rendered).to have_css("img[src*='/raw/#{diff_file.old_content_sha}/files/ruby/popen.rb']")
  end

  context 'when the file path contains traversal segments' do
    before do
      allow(diff_file).to receive(:path_traversal?).and_return(true)
    end

    it 'falls back to the placeholder rather than raising on the dropped URL' do
      expect { render_view }.not_to raise_error

      expect(rendered_image_srcs).not_to be_empty
      expect(rendered_image_srcs.uniq).to eq([placeholder])
    end
  end
end
