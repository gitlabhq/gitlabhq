# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "ExternalRedirect::ExternalRedirectController requests", feature_category: :navigation do
  let_it_be(:external_url) { 'https://google.com' }
  let_it_be(:external_url_encoded) do
    Addressable::URI.encode_component(external_url, Addressable::URI::CharacterClasses::QUERY)
  end

  let_it_be(:internal_url) { "#{Gitlab.config.gitlab.url}/foo/bar" }
  let_it_be(:internal_url_encoded) do
    Addressable::URI.encode_component(internal_url, Addressable::URI::CharacterClasses::QUERY)
  end

  let_it_be(:top_nav_partial) { 'layouts/header/_default' }

  context "with valid url param" do
    before do
      get "/-/external_redirect?url=#{external_url_encoded}"
    end

    it "returns 200 and renders URL" do
      expect(response).to have_gitlab_http_status(:ok)
      expect(response.body).to have_link(text: 'Proceed', href: external_url)
    end

    it "does not render nav" do
      expect(response).not_to render_template(top_nav_partial)
    end
  end

  context "with same origin url" do
    before do
      get "/-/external_redirect?url=#{internal_url_encoded}"
    end

    it "redirects" do
      expect(response).to redirect_to(internal_url)
    end
  end

  describe "with invalid url params" do
    where(:case_name, :params) do
      [
        ["when url is bad", "url=javascript:alert(1)"],
        ["when url is empty", "url="],
        ["when url param is missing", ""],
        ["when url points to self", "url=http://www.example.com/-/external_redirect?url=#{external_url_encoded}"],
        ["when url points to self encoded",
          "url=http%3A%2F%2Fwww.example.com/-/external_redirect?url=#{external_url_encoded}"]
      ]
    end

    with_them do
      it "returns 404" do
        get "/-/external_redirect?#{params}"

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
