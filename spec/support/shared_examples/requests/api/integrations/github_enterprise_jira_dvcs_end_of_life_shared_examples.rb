# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples 'a GitHub Enterprise Jira DVCS reversible end of life endpoint' do
  it 'is a reachable endpoint' do
    subject

    expect(response).not_to have_gitlab_http_status(:not_found)
  end

  context 'when the flag is disabled' do
    before do
      stub_feature_flags(jira_dvcs_end_of_life_amnesty: false)
    end

    it 'presents as an endpoint that does not exist' do
      subject

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end
end
