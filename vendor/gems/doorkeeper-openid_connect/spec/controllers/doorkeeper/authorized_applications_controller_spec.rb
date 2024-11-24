# frozen_string_literal: true

require 'rails_helper'

describe Doorkeeper::AuthorizedApplicationsController, type: :controller do
  let(:access_token) { create :access_token }

  describe '#index' do
    it 'does not run the extended #authenticate_resource_owner!' do
      expect do
        get :index
      end.not_to raise_error
    end
  end
end
