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

  describe '#candidates_order_params' do
    using RSpec::Parameterized::TableSyntax

    subject { candidates_order_params(params) }

    where(:input, :order_by, :order_by_type, :sort) do
      ''                            | nil          | nil      | nil
      'created_at'                  | 'created_at' | 'column' | nil
      'created_at ASC'              | 'created_at' | 'column' | 'ASC'
      'metrics.something'           | 'something'  | 'metric' | nil
      'metrics.something asc'       | 'something'  | 'metric' | 'asc'
      'metrics.something.blah asc'  | 'something'  | 'metric' | 'asc'
      'params.something ASC'        | nil          | nil      | 'ASC'
      'metadata.something ASC'      | nil          | nil      | 'ASC'
    end
    with_them do
      let(:params) { { order_by: input } }

      it 'is correct' do
        is_expected.to include({ order_by: order_by, order_by_type: order_by_type, sort: sort })
      end
    end
  end

  describe '#model_order_params' do
    using RSpec::Parameterized::TableSyntax

    subject { model_order_params(params) }

    where(:input, :order_by, :sort) do
      ''                            | 'name'        | 'asc'
      'name'                        | 'name'        | 'asc'
      'name DESC'                   | 'name'        | 'desc'
      'last_updated_timestamp'      | 'updated_at'  | 'asc'
      'last_updated_timestamp asc'  | 'updated_at'  | 'asc'
      'last_updated_timestamp DESC' | 'updated_at'  | 'desc'
    end
    with_them do
      let(:params) { { order_by: input } }

      it 'is correct' do
        is_expected.to include({ order_by: order_by, sort: sort })
      end
    end
  end

  describe '#model_filter_params' do
    using RSpec::Parameterized::TableSyntax

    subject { model_filter_params(params) }

    where(:input, :output) do
      ''                            | {}
      'name=""'                     | { name: '' }
      'name=foo'                    | { name: 'foo' }
      'name="foo"'                  | { name: 'foo' }
      'invalid="foo"'               | {}
    end
    with_them do
      let(:params) { { filter: input } }

      it 'is correct' do
        is_expected.to eq(output)
      end
    end
  end
end
