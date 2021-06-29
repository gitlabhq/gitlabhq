# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Updating the container expiration policy' do
  include GraphqlHelpers
  using RSpec::Parameterized::TableSyntax

  let_it_be(:project, reload: true) { create(:project) }
  let_it_be(:user) { create(:user) }

  let(:container_expiration_policy) { project.container_expiration_policy.reload }
  let(:params) do
    {
      project_path: project.full_path,
      cadence: 'EVERY_THREE_MONTHS',
      keep_n: 'ONE_HUNDRED_TAGS',
      older_than: 'FOURTEEN_DAYS'
    }
  end

  let(:mutation) do
    graphql_mutation(:update_container_expiration_policy, params,
                     <<~QL
                       containerExpirationPolicy {
                         cadence
                         keepN
                         nameRegexKeep
                         nameRegex
                         olderThan
                       }
                       errors
                     QL
    )
  end

  let(:mutation_response) { graphql_mutation_response(:update_container_expiration_policy) }
  let(:container_expiration_policy_response) { mutation_response['containerExpirationPolicy'] }

  RSpec.shared_examples 'returning a success' do
    it_behaves_like 'returning response status', :success

    it 'returns the updated container expiration policy' do
      subject

      expect(mutation_response['errors']).to be_empty
      expect(container_expiration_policy_response['cadence']).to eq(params[:cadence])
      expect(container_expiration_policy_response['keepN']).to eq(params[:keep_n])
      expect(container_expiration_policy_response['olderThan']).to eq(params[:older_than])
    end
  end

  RSpec.shared_examples 'rejecting invalid regex for' do |field_name|
    context "for field #{field_name}" do
      let_it_be(:invalid_regex) { '*production' }

      let(:params) do
        {
          :project_path => project.full_path,
          field_name => invalid_regex
        }
      end

      it_behaves_like 'returning response status', :success

      it_behaves_like 'not creating the container expiration policy'

      it 'returns an error' do
        subject

        expect(graphql_errors.size).to eq(1)
        expect(graphql_errors.first['message']).to include("#{invalid_regex} is an invalid regexp")
      end
    end
  end

  RSpec.shared_examples 'rejecting blank name_regex when enabled' do
    context "for blank name_regex" do
      let(:params) do
        {
          project_path: project.full_path,
          name_regex: '',
          enabled: true
        }
      end

      it_behaves_like 'returning response status', :success

      it_behaves_like 'not creating the container expiration policy'

      it 'returns an error' do
        subject

        expect(graphql_data['updateContainerExpirationPolicy']['errors'].size).to eq(1)
        expect(graphql_data['updateContainerExpirationPolicy']['errors']).to include("Name regex can't be blank")
      end
    end
  end

  RSpec.shared_examples 'accepting the mutation request updating the container expiration policy' do
    it_behaves_like 'updating the container expiration policy attributes', mode: :update, from: { cadence: '1d', keep_n: 10, older_than: '90d' }, to: { cadence: '3month', keep_n: 100, older_than: '14d' }

    it_behaves_like 'returning a success'

    it_behaves_like 'rejecting invalid regex for', :name_regex
    it_behaves_like 'rejecting invalid regex for', :name_regex_keep
    it_behaves_like 'rejecting blank name_regex when enabled'
  end

  RSpec.shared_examples 'accepting the mutation request creating the container expiration policy' do
    it_behaves_like 'creating the container expiration policy'

    it_behaves_like 'returning a success'

    it_behaves_like 'rejecting invalid regex for', :name_regex
    it_behaves_like 'rejecting invalid regex for', :name_regex_keep
    it_behaves_like 'rejecting blank name_regex when enabled'
  end

  RSpec.shared_examples 'denying the mutation request' do
    it_behaves_like 'not creating the container expiration policy'

    it_behaves_like 'returning response status', :success

    it 'returns no response' do
      subject

      expect(mutation_response).to be_nil
    end
  end

  describe 'post graphql mutation' do
    subject { post_graphql_mutation(mutation, current_user: user) }

    context 'with existing container expiration policy' do
      where(:user_role, :shared_examples_name) do
        :maintainer | 'accepting the mutation request updating the container expiration policy'
        :developer  | 'accepting the mutation request updating the container expiration policy'
        :reporter   | 'denying the mutation request'
        :guest      | 'denying the mutation request'
        :anonymous  | 'denying the mutation request'
      end

      with_them do
        before do
          project.send("add_#{user_role}", user) unless user_role == :anonymous
        end

        it_behaves_like params[:shared_examples_name]
      end
    end

    context 'without existing container expiration policy' do
      let_it_be(:project, reload: true) { create(:project, :without_container_expiration_policy) }

      where(:user_role, :shared_examples_name) do
        :maintainer | 'accepting the mutation request creating the container expiration policy'
        :developer  | 'accepting the mutation request creating the container expiration policy'
        :reporter   | 'denying the mutation request'
        :guest      | 'denying the mutation request'
        :anonymous  | 'denying the mutation request'
      end

      with_them do
        before do
          project.send("add_#{user_role}", user) unless user_role == :anonymous
        end

        it_behaves_like params[:shared_examples_name]
      end
    end
  end
end
