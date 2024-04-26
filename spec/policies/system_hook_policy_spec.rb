# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SystemHookPolicy, feature_category: :webhooks do
  let(:hook) { create(:system_hook) }

  subject(:policy) { described_class.new(user, hook) }

  context 'when the user is not an admin' do
    let(:user) { create(:user) }

    %i[read_web_hook admin_web_hook].each do |thing|
      it "cannot #{thing}" do
        expect(policy).to be_disallowed(thing)
      end
    end
  end

  context 'when the user is an admin', :enable_admin_mode do
    let(:user) { create(:admin) }

    %i[read_web_hook admin_web_hook].each do |thing|
      it "can #{thing}" do
        expect(policy).to be_allowed(thing)
      end
    end
  end
end
