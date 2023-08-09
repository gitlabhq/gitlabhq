# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Ml::Mlflow::ApiHelpers, feature_category: :mlops do
  include described_class

  describe '#packages_url' do
    subject { packages_url }

    let_it_be(:user_project) { build_stubbed(:project) }

    context 'with an empty relative URL root' do
      before do
        allow(Gitlab::Application.routes).to receive(:default_url_options)
          .and_return(protocol: 'http', host: 'localhost', script_name: '')
      end

      it { is_expected.to eql("http://localhost/api/v4/projects/#{user_project.id}/packages/generic") }
    end

    context 'with a forward slash relative URL root' do
      before do
        allow(Gitlab::Application.routes).to receive(:default_url_options)
          .and_return(protocol: 'http', host: 'localhost', script_name: '/')
      end

      it { is_expected.to eql("http://localhost/api/v4/projects/#{user_project.id}/packages/generic") }
    end

    context 'with a relative URL root' do
      before do
        allow(Gitlab::Application.routes).to receive(:default_url_options)
          .and_return(protocol: 'http', host: 'localhost', script_name: '/gitlab/root')
      end

      it { is_expected.to eql("http://localhost/gitlab/root/api/v4/projects/#{user_project.id}/packages/generic") }
    end
  end
end
