# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ml::ModelsIndexPresenter, feature_category: :mlops do
  let_it_be(:project) { build_stubbed(:project) }
  let_it_be(:model1) { build_stubbed(:ml_models, :with_latest_version_and_package, project: project) }
  let_it_be(:model2) { build_stubbed(:ml_models, project: project) }
  let_it_be(:models) do
    [model1, model2]
  end

  describe '#execute' do
    subject { Gitlab::Json.parse(described_class.new(models).present)['models'] }

    it 'presents models correctly' do
      expected_models = [
        {
          'name' => model1.name,
          'version' => model1.latest_version.version,
          'path' => "/#{project.full_path}/-/packages/#{model1.latest_version.package_id}"
        },
        {
          'name' => model2.name,
          'version' => nil,
          'path' => nil
        }
      ]

      is_expected.to match_array(expected_models)
    end
  end
end
