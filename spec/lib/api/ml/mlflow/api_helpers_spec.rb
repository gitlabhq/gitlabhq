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
        expect(gitlab_tags).to be_nil
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

  describe '#icandidate_version?' do
    describe 'when version is nil' do
      let(:version) { nil }

      it 'returns false' do
        expect(candidate_version?(version)).to be false
      end
    end

    describe 'when version has candidate prefix' do
      let(:version) { 'candidate:1' }

      it 'returns true' do
        expect(candidate_version?(version)).to be true
      end
    end

    describe 'when version does not have candidate prefix' do
      let(:version) { '1' }

      it 'returns false' do
        expect(candidate_version?(version)).to be false
      end
    end
  end

  describe '#find_run_artifact' do
    let_it_be(:project) { create(:project) }
    let_it_be(:candidate) { create(:ml_candidates, :with_ml_model, project: project) }
    let_it_be(:candidate_package_file) { create(:package_file, :ml_model, package: candidate.package) }

    it 'returns list of files' do
      expect(find_run_artifact(project, candidate.iid, candidate_package_file.file_name)).to eq candidate_package_file
    end
  end

  describe '#list_run_artifacts' do
    let_it_be(:project) { create(:project) }
    let_it_be(:candidate) { create(:ml_candidates, :with_ml_model, project: project) }
    let_it_be(:candidate_package_file) { create(:package_file, :ml_model, package: candidate.package) }
    let_it_be(:candidate_package_file_2) { create(:package_file, :ml_model, package: candidate.package) }

    it 'returns list of files' do
      expect(list_run_artifacts(project,
        candidate.iid)).to match_array [candidate_package_file, candidate_package_file_2]
    end
  end
end
