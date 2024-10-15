# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::BroadcastMessagePlaceholdersFilter, feature_category: :markdown do
  include FilterSpecHelper

  subject { filter(text, current_user: user, broadcast_message_placeholders: true).to_html }

  describe 'when current user is set' do
    let_it_be(:user) { create(:user, email: "helloworld@example.com", name: "GitLab Tanunki :)") }

    context 'replaces placeholder in text' do
      let(:text) { 'Email: {{email}}' }

      it { expect(subject).to eq("Email: #{user.email}") }
    end

    context 'replaces placeholder when they are in a link' do
      let(:text) { '<a href="http://example.com?email={{email}}"">link</a>' }

      it { expect(subject).to eq("<a href=\"http://example.com?email=helloworld%40example.com\">link</a>") }
    end

    context 'replaces placeholder when they are in an escaped link' do
      let(:text) { '<a href="http://example.com?name=%7B%7Bname%7D%7D">link</a>' }

      it { expect(subject).to eq("<a href=\"http://example.com?name=GitLab+Tanunki+%3A%29\">link</a>") }
    end

    context 'works with empty text' do
      let(:text) { " " }

      it { expect(subject).to eq(" ") }
    end

    context 'replaces multiple placeholders in a given text' do
      let(:text) { "{{email}} {{name}}" }

      it { expect(subject).to eq("#{user.email} #{user.name}") }
    end

    context 'available placeholders' do
      context 'replaces the email of the user' do
        let(:text) { "{{email}}" }

        it { expect(subject).to eq(user.email) }
      end

      context 'replaces the name of the user' do
        let(:text) { "{{name}}" }

        it { expect(subject).to eq(user.name) }
      end

      context 'replaces the ID of the user' do
        let(:text) { "{{user_id}}" }

        it { expect(subject).to eq(user.id.to_s) }
      end

      context 'replaces the username of the user' do
        let(:text) { "{{username}}" }

        it { expect(subject).to eq(user.username) }
      end

      context 'replaces the instance_id' do
        before do
          stub_application_setting(uuid: '123')
        end

        let(:text) { "{{instance_id}}" }

        it { expect(subject).to eq(Gitlab::CurrentSettings.uuid) }
      end
    end
  end

  describe 'when there is no current user set' do
    let(:user) { nil }

    context 'replaces placeholder with empty string' do
      let(:text) { "Email: {{email}}" }

      it { expect(subject).to eq("Email: ") }
    end
  end

  it_behaves_like 'pipeline timing check'
end
