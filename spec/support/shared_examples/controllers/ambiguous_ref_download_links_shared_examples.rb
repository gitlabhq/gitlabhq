# frozen_string_literal: true

# Shared examples asserting that, for an ambiguous branch/tag ref, the page's
# archive download links stay anchored to the same ref the page resolved. This
# prevents the displayed ref and a download from diverging when a branch and a
# tag share a name (https://gitlab.com/gitlab-org/gitlab/-/issues/578988).
#
# The including context must provide:
#   - a `get_show(ref_type:)` helper that issues the request for the ambiguous ref
#
# Both the blob and tree views render their download links into the
# `#js-repository-blob-header-app` node's `data-download-links` attribute.
RSpec.shared_examples 'an ambiguous ref with divergent branch and tag content' do
  it 'has a branch and a tag pointing at different commits' do
    expect(branch_sha).not_to eq(tag_sha)
  end
end

RSpec.shared_examples 'archive download links anchored to the ref_type' do |ref_type:|
  def archive_download_paths(body)
    download_links = Nokogiri::HTML(body)
      .at_css('#js-repository-blob-header-app')
      &.attr('data-download-links')

    Gitlab::Json.safe_parse(download_links.to_s).pluck('path')
  end

  it "anchors the archive download links to ref_type=#{ref_type}" do
    get_show(ref_type: ref_type)

    expect(response).to have_gitlab_http_status(:ok)

    other_ref_type = ref_type == 'heads' ? 'tags' : 'heads'
    archive_paths = archive_download_paths(response.body)

    expect(archive_paths).to all(include("ref_type=#{ref_type}"))
    expect(archive_paths).to all(exclude("ref_type=#{other_ref_type}"))
  end
end

RSpec.shared_examples 'archive download links not anchored to a ref_type' do
  it 'does not silently anchor the archive download links to a ref_type' do
    get_show(ref_type: nil)

    expect(response).to have_gitlab_http_status(:ok)

    download_links = Nokogiri::HTML(response.body)
      .at_css('#js-repository-blob-header-app')
      &.attr('data-download-links')
    archive_paths = Gitlab::Json.safe_parse(download_links.to_s).pluck('path')

    expect(archive_paths).to all(exclude('ref_type=heads'))
    expect(archive_paths).to all(exclude('ref_type=tags'))
  end
end
