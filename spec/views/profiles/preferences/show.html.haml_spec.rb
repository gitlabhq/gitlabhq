# frozen_string_literal: true

require 'spec_helper'

describe 'profiles/preferences/show' do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:user) { build(:user) }

  before do
    assign(:user, user)
    allow(controller).to receive(:current_user).and_return(user)
  end

  context 'sourcegraph' do
    def have_sourcegraph_field(*args)
      have_field('user_sourcegraph_enabled', *args)
    end

    def have_integrations_section
      have_css('.profile-settings-sidebar', { text: 'Integrations' })
    end

    before do
      # Can't use stub_feature_flags because we use Feature.get to check if conditinally applied
      Feature.get(:sourcegraph).enable sourcegraph_feature
      stub_application_setting(sourcegraph_enabled: sourcegraph_enabled)
    end

    context 'when not fully enabled' do
      where(:feature, :admin_enabled) do
        false | false
        false | true
        true | false
      end

      with_them do
        let(:sourcegraph_feature) { feature }
        let(:sourcegraph_enabled) { admin_enabled }

        before do
          render
        end

        it 'does not display sourcegraph field' do
          expect(rendered).not_to have_sourcegraph_field
        end

        it 'does not display integrations settings' do
          expect(rendered).not_to have_integrations_section
        end
      end
    end

    context 'when fully enabled' do
      let(:sourcegraph_feature) { true }
      let(:sourcegraph_enabled) { true }

      before do
        render
      end

      it 'displays the sourcegraph field' do
        expect(rendered).to have_sourcegraph_field
      end

      it 'displays the integrations section' do
        expect(rendered).to have_integrations_section
      end
    end
  end
end
