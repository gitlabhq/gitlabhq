# frozen_string_literal: true

RSpec.shared_examples "an atom feed with absolute reference URLs" do
  it "resolves references in the content to absolute URLs", :aggregate_failures do
    hrefs = atom_rendered_link_hrefs(body)

    expect(hrefs).to be_present
    expect(hrefs).to all(start_with(Gitlab.config.gitlab.url))
  end
end
