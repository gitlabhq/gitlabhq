# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Admin::AbuseReportLabels::Create, feature_category: :insider_threat do
  include GraphqlHelpers

  let(:params) do
    {
      'title' => 'foo',
      'color' => '#FF0000'
    }
  end

  let(:mutation) { graphql_mutation(:abuse_report_label_create, params) }

  subject { post_graphql_mutation(mutation, current_user: current_user) }

  def mutation_response
    graphql_mutation_response(:abuse_report_label_create)
  end

  context 'when the user does not have permission to create a label', :enable_admin_mode do
    let_it_be(:current_user) { create(:user) }

    it_behaves_like 'a mutation that returns a top-level access error'

    it 'does not create the label' do
      expect { subject }.not_to change { AntiAbuse::Reports::Label.count }
    end
  end

  context 'when the user has permission to create a label', :enable_admin_mode do
    let_it_be(:current_user) { create(:admin) }

    it 'creates the label' do
      expect { subject }.to change { AntiAbuse::Reports::Label.count }.to(1)

      expect(mutation_response).to include('label' => a_hash_including(params))
    end

    context 'when there are errors' do
      it 'does not create the label', :aggregate_failures do
        create(:abuse_report_label, title: params['title'])

        expect { subject }.not_to change { AntiAbuse::Reports::Label.count }

        expect(mutation_response).to include({
          'label' => nil,
          'errors' => ['Title has already been taken']
        })
      end
    end
  end
end
