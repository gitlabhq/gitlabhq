# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'profiles/keys/_key_details.html.haml' do
  let_it_be(:user) { create(:user) }

  before do
    assign(:key, key)
    allow(view).to receive(:is_admin).and_return(false)
  end

  describe 'displays the usage type' do
    where(:usage_type, :usage_type_text) do
      [
        [:auth, 'Authentication'],
        [:auth_and_signing, 'Authentication & Signing'],
        [:signing, 'Signing']
      ]
    end

    with_them do
      let(:key) { create(:key, user: user, usage_type: usage_type) }

      it 'renders usage type text' do
        render

        expect(rendered).to have_text(usage_type_text)
      end
    end
  end
end
