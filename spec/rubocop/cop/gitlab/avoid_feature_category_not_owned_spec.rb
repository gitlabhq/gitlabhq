# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/gitlab/avoid_feature_category_not_owned'

RSpec.describe RuboCop::Cop::Gitlab::AvoidFeatureCategoryNotOwned do
  shared_examples 'defining feature category on a class' do
    it 'flags a method call on a class' do
      expect_offense(<<~SOURCE)
        feature_category :not_owned
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid adding new endpoints with `feature_category :not_owned`. See https://docs.gitlab.com/ee/development/feature_categorization
      SOURCE
    end

    it 'flags a method call on a class with an array passed' do
      expect_offense(<<~SOURCE)
        feature_category :not_owned, [:index, :edit]
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid adding new endpoints with `feature_category :not_owned`. See https://docs.gitlab.com/ee/development/feature_categorization
      SOURCE
    end

    it 'flags a method call on a class with an array passed' do
      expect_offense(<<~SOURCE)
        worker.feature_category :not_owned, [:index, :edit]
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid adding new endpoints with `feature_category :not_owned`. See https://docs.gitlab.com/ee/development/feature_categorization
      SOURCE
    end
  end

  context 'in controllers' do
    before do
      allow(cop).to receive(:in_controller?).and_return(true)
    end

    it_behaves_like 'defining feature category on a class'
  end

  context 'in workers' do
    before do
      allow(cop).to receive(:in_worker?).and_return(true)
    end

    it_behaves_like 'defining feature category on a class'
  end

  context 'for grape endpoints' do
    before do
      allow(cop).to receive(:in_api?).and_return(true)
    end

    it_behaves_like 'defining feature category on a class'

    it 'flags when passed as a hash for a Grape endpoint as keyword args' do
      expect_offense(<<~SOURCE)
        get :hello, feature_category: :not_owned
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid adding new endpoints with `feature_category :not_owned`. See https://docs.gitlab.com/ee/development/feature_categorization
      SOURCE
    end

    it 'flags when passed as a hash for a Grape endpoint in a hash' do
      expect_offense(<<~SOURCE)
        get :hello, { feature_category: :not_owned, urgency: :low}
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid adding new endpoints with `feature_category :not_owned`. See https://docs.gitlab.com/ee/development/feature_categorization
      SOURCE
    end
  end
end
