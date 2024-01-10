# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Ml::Mlflow::ApiHelpers, feature_category: :mlops do
  include described_class

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

  describe '#gitlab_tags' do
    describe 'when tags param is not supplied' do
      let(:params) { {} }

      it 'returns nil' do
        expect(gitlab_tags).to be nil
      end
    end

    describe 'when tags param is supplied' do
      let(:params) { { tags: input } }

      using RSpec::Parameterized::TableSyntax

      subject { gitlab_tags }

      where(:input, :output) do
        []                                                                  | nil
        [{}]                                                                | {}
        [{ key: 'foo', value: 'bar' }]                                      | {}
        [{ key: "gitlab.version", value: "1.2.3" }]                         | { "version" => "1.2.3" }
        [{ key: "foo", value: "bar" }, { key: "gitlab.foo", value: "baz" }] | { "foo" => "baz" }
      end
      with_them do
        it 'is correct' do
          is_expected.to eq(output)
        end
      end
    end
  end

  describe '#custom_version' do
    using RSpec::Parameterized::TableSyntax

    subject { custom_version }

    where(:input, :output) do
      []                                                                | nil
      [{}]                                                              | nil
      [{ key: 'foo', value: 'bar' }] | nil
      [{ key: "gitlab.version", value: "1.2.3" }] | "1.2.3"
      [{ key: "foo", value: "bar" }, { key: "gitlab.foo", value: "baz" }] | nil
    end
    with_them do
      let(:params) { { tags: input } }

      it 'is correct' do
        is_expected.to eq(output)
      end
    end
  end
end
