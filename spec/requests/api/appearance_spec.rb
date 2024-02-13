# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Appearance, 'Appearance', :aggregate_failures, feature_category: :navigation do
  let_it_be(:user) { create(:user) }
  let_it_be(:admin) { create(:admin) }
  let_it_be(:path) { "/application/appearance" }

  describe "GET /application/appearance" do
    it_behaves_like 'GET request permissions for admin mode'

    context 'as an admin user' do
      it "returns appearance" do
        get api(path, admin, admin_mode: true)

        expect(json_response).to be_an Hash
        expect(json_response['description']).to eq('')
        expect(json_response['email_header_and_footer_enabled']).to be(false)
        expect(json_response['pwa_icon']).to be_nil
        expect(json_response['favicon']).to be_nil
        expect(json_response['footer_message']).to eq('')
        expect(json_response['header_logo']).to be_nil
        expect(json_response['header_message']).to eq('')
        expect(json_response['logo']).to be_nil
        expect(json_response['message_background_color']).to eq('#E75E40')
        expect(json_response['message_font_color']).to eq('#FFFFFF')
        expect(json_response['member_guidelines']).to eq('')
        expect(json_response['new_project_guidelines']).to eq('')
        expect(json_response['profile_image_guidelines']).to eq('')
        expect(json_response['title']).to eq('')
        expect(json_response['pwa_name']).to eq('')
        expect(json_response['pwa_short_name']).to eq('')
        expect(json_response['pwa_description']).to eq('')
      end
    end
  end

  describe "PUT /application/appearance" do
    it_behaves_like 'PUT request permissions for admin mode' do
      let(:params) { { title: "Test" } }
    end

    context 'as an admin user' do
      context "instance basics" do
        it "allows updating the settings" do
          put api(path, admin, admin_mode: true), params: {
            title: "GitLab Test Instance",
            description: "gitlab-test.example.com",
            pwa_name: "GitLab PWA Test",
            pwa_short_name: "GitLab PWA",
            pwa_description: "This is GitLab as PWA",
            member_guidelines: "Please read before adding members.",
            new_project_guidelines: "Please read the FAQs for help.",
            profile_image_guidelines: "Custom profile image guidelines"
          }

          expect(json_response).to be_an Hash
          expect(json_response['description']).to eq('gitlab-test.example.com')
          expect(json_response['email_header_and_footer_enabled']).to be(false)
          expect(json_response['pwa_icon']).to be_nil
          expect(json_response['favicon']).to be_nil
          expect(json_response['footer_message']).to eq('')
          expect(json_response['header_logo']).to be_nil
          expect(json_response['header_message']).to eq('')
          expect(json_response['logo']).to be_nil
          expect(json_response['message_background_color']).to eq('#E75E40')
          expect(json_response['message_font_color']).to eq('#FFFFFF')
          expect(json_response['member_guidelines']).to eq('Please read before adding members.')
          expect(json_response['new_project_guidelines']).to eq('Please read the FAQs for help.')
          expect(json_response['profile_image_guidelines']).to eq('Custom profile image guidelines')
          expect(json_response['title']).to eq('GitLab Test Instance')
          expect(json_response['pwa_name']).to eq('GitLab PWA Test')
          expect(json_response['pwa_short_name']).to eq('GitLab PWA')
          expect(json_response['pwa_description']).to eq('This is GitLab as PWA')
        end
      end

      context "system header and footer" do
        it "allows updating the settings" do
          settings = {
            footer_message: "This is a Header",
            header_message: "This is a Footer",
            message_font_color: "#ffffff",
            message_background_color: "#009999",
            email_header_and_footer_enabled: true
          }

          put api(path, admin, admin_mode: true), params: settings

          expect(response).to have_gitlab_http_status(:ok)
          settings.each do |attribute, value|
            expect(Appearance.current.public_send(attribute)).to eq(value)
          end
        end

        context "fails on invalid color values" do
          it "with message_font_color" do
            put api(path, admin, admin_mode: true), params: { message_font_color: "No Color" }

            expect(response).to have_gitlab_http_status(:bad_request)
            expect(json_response['message']['message_font_color']).to contain_exactly('must be a valid color code')
          end

          it "with message_background_color" do
            put api(path, admin, admin_mode: true), params: { message_background_color: "#1" }

            expect(response).to have_gitlab_http_status(:bad_request)
            expect(json_response['message']['message_background_color']).to contain_exactly('must be a valid color code')
          end
        end
      end

      context "instance logos" do
        let_it_be(:appearance) { create(:appearance) }

        it "allows updating the image files" do
          put api(path, admin, admin_mode: true), params: {
            logo: fixture_file_upload("spec/fixtures/dk.png", "image/png"),
            header_logo: fixture_file_upload("spec/fixtures/dk.png", "image/png"),
            pwa_icon: fixture_file_upload("spec/fixtures/dk.png", "image/png"),
            favicon: fixture_file_upload("spec/fixtures/dk.png", "image/png")
          }

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['logo']).to eq("/uploads/-/system/appearance/logo/#{appearance.id}/dk.png")
          expect(json_response['header_logo']).to eq("/uploads/-/system/appearance/header_logo/#{appearance.id}/dk.png")
          expect(json_response['pwa_icon']).to eq("/uploads/-/system/appearance/pwa_icon/#{appearance.id}/dk.png")
          expect(json_response['favicon']).to eq("/uploads/-/system/appearance/favicon/#{appearance.id}/dk.png")
        end

        context "fails on invalid color images" do
          it "with string instead of file" do
            put api(path, admin, admin_mode: true), params: { logo: 'not-a-file.png' }

            expect(response).to have_gitlab_http_status(:bad_request)
            expect(json_response['error']).to eq("logo is invalid")
          end

          it "with .svg file instead of .png" do
            put api(path, admin, admin_mode: true), params: { favicon: fixture_file_upload("spec/fixtures/logo_sample.svg", "image/svg") }

            expect(response).to have_gitlab_http_status(:bad_request)
            expect(json_response['message']['favicon']).to contain_exactly("You are not allowed to upload \"svg\" files, allowed types: png, ico")
          end
        end
      end
    end
  end
end
