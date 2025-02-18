# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Conan::SearchService, feature_category: :package_registry do
  describe '#execute' do
    using RSpec::Parameterized::TableSyntax

    let_it_be(:user) { create(:user) }
    let_it_be(:project1) { create(:project, :public, developers: user) }
    let_it_be(:project2) { create(:project, :public) }

    let_it_be(:alpha_1_2_0) { create(:conan_package, project: project1, name: 'alpha', version: '1.2.0') }
    let_it_be(:alpha_1_2_1) { create(:conan_package, project: project1, name: 'alpha', version: '1.2.1') }
    let_it_be(:alpha_2_0_0) { create(:conan_package, project: project1, name: 'alpha', version: '2.0.0') }
    let_it_be(:beta_1_2_0) { create(:conan_package, project: project1, name: 'beta', version: '1.2.0') }

    let_it_be(:gamma_1_2_0) { create(:conan_package, project: project2, name: 'gamma', version: '1.2.0') }

    let_it_be(:username) { ::Packages::Conan::Metadatum.package_username_from(full_path: project1.full_path) }

    subject(:search_result) { described_class.new(project, user, query: query).execute }

    context 'with search query' do
      # rubocop:disable Layout/LineLength -- Avoid formatting to keep one-line table syntax
      where(:project, :query, :expected_packages) do
        # Project package search
        ref(:project1) | 'alpha'                                   | [ref(:alpha_1_2_0), ref(:alpha_1_2_1), ref(:alpha_2_0_0)]
        ref(:project1) | lazy { "alpha/1.2.0@#{username}/stable" } | [ref(:alpha_1_2_0)]
        ref(:project1) | lazy { "a*/1.2.0@#{username}/stable" }    | [ref(:alpha_1_2_0)]
        ref(:project1) | 'b*/1.2.0'                                | [ref(:beta_1_2_0)]
        ref(:project1) | 'alpha/1.2.*'                             | [ref(:alpha_1_2_0), ref(:alpha_1_2_1)]
        ref(:project1) | 'alph*'                                   | [ref(:alpha_1_2_0), ref(:alpha_1_2_1), ref(:alpha_2_0_0)]
        ref(:project1) | lazy { "a*p*a/*@#{username}/stable" }     | [ref(:alpha_1_2_0), ref(:alpha_1_2_1), ref(:alpha_2_0_0)]
        ref(:project1) | '*'                                       | []
        ref(:project1) | '*/*'                                     | []
        ref(:project1) | lazy { "*/*@#{username}/stable" }         | []
        ref(:project1) | ';DROP TABLE foo;'                        | []
        ref(:project1) | 'alpha/*hannel'                           | []
        ref(:project1) | 'beta/1.0.0@*hannel'                      | []
        # Instance package search
        nil | lazy { "*a/*@#{username}/stable" } | [ref(:alpha_1_2_0), ref(:alpha_1_2_1), ref(:alpha_2_0_0), ref(:beta_1_2_0)]
        nil | '*a/*'                             | [ref(:alpha_1_2_0), ref(:alpha_1_2_1), ref(:alpha_2_0_0), ref(:beta_1_2_0), ref(:gamma_1_2_0)]
      end
      # rubocop:enable Layout/LineLength

      with_them do
        it 'returns matching packages' do
          expect(search_result.status).to eq :success
          expect(search_result.payload[:results]).to match_array(expected_packages.map(&:conan_recipe))
        end
      end
    end

    context 'with invalid search query' do # -- Avoid formatting to keep one-line table syntax
      where(:project, :query, :expected_error_message) do
        # Project package search
        ref(:project1) | 'al*h*/*@*nn*/*' | 'Too many wildcards in search term. Maximum is 5.'
        ref(:project1) | ('q' * 201)      | 'Search term length must be less than 200 characters.'
      end
      with_them do
        it 'returns matching packages' do
          expect(search_result.status).to eq :error
          expect(search_result.message).to eq(expected_error_message)
          expect(search_result.reason).to eq(:invalid_parameter)
        end
      end
    end
  end
end
