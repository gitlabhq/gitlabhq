# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ReviewAppSetupEntity do
  let_it_be(:user) { create(:admin) }

  let(:project) { create(:project) }
  let(:presenter) { ProjectPresenter.new(project, current_user: user) }
  let(:entity) { described_class.new(presenter) }
  let(:request) { double('request') }

  before do
    allow(request).to receive(:current_user).and_return(user)
    allow(request).to receive(:project).and_return(project)
  end

  subject { entity.as_json }

  describe '#as_json' do
    it 'contains can_setup_review_app' do
      expect(subject).to include(:can_setup_review_app)
    end

    context 'when the user can setup a review app' do
      before do
        allow(presenter).to receive(:can_setup_review_app?).and_return(true)
      end

      it 'contains relevant fields' do
        expect(subject.keys).to include(:all_clusters_empty, :review_snippet)
      end

      it 'exposes the relevant review snippet' do
        review_app_snippet = YAML.safe_load(File.read(Rails.root.join('lib', 'gitlab', 'ci', 'snippets', 'review_app_default.yml'))).to_s

        expect(subject[:review_snippet]).to eq(review_app_snippet)
      end

      it 'exposes whether the project has associated clusters' do
        expect(subject[:all_clusters_empty]).to be_truthy
      end
    end

    context 'when the user cannot setup a review app' do
      before do
        allow(presenter).to receive(:can_setup_review_app?).and_return(false)
      end

      it 'does not expose certain fields' do
        expect(subject.keys).not_to include(:all_clusters_empty, :review_snippet)
      end
    end
  end
end
