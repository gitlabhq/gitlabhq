# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::External::File::Template do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  let(:context_params) { { project: project, sha: '12345', user: user } }
  let(:context) { Gitlab::Ci::Config::External::Context.new(**context_params) }
  let(:template) { 'Auto-DevOps.gitlab-ci.yml' }
  let(:params) { { template: template } }
  let(:template_file) { described_class.new(params, context) }

  before do
    allow_next_instance_of(Gitlab::Ci::Config::External::Context) do |instance|
      allow(instance).to receive(:check_execution_time!)
    end
  end

  describe '#matching?' do
    context 'when a template is specified' do
      let(:params) { { template: 'some-template' } }

      it 'returns true' do
        expect(template_file).to be_matching
      end
    end

    context 'with a missing template' do
      let(:params) { { template: nil } }

      it 'returns false' do
        expect(template_file).not_to be_matching
      end
    end

    context 'with a missing template key' do
      let(:params) { {} }

      it 'returns false' do
        expect(template_file).not_to be_matching
      end
    end
  end

  describe "#valid?" do
    context 'when is a valid template name' do
      let(:template) { 'Auto-DevOps.gitlab-ci.yml' }

      it 'returns true' do
        expect(template_file).to be_valid
      end
    end

    context 'with invalid template name' do
      let(:template) { 'Template.yml' }

      it 'returns false' do
        expect(template_file).not_to be_valid
        expect(template_file.error_message).to include('Template file `Template.yml` is not a valid location!')
      end
    end

    context 'with a non-existing template' do
      let(:template) { 'I-Do-Not-Have-This-Template.gitlab-ci.yml' }

      it 'returns false' do
        expect(template_file).not_to be_valid
        expect(template_file.error_message).to include('Included file `I-Do-Not-Have-This-Template.gitlab-ci.yml` is empty or does not exist!')
      end
    end
  end

  describe '#template_name' do
    let(:template_name) { template_file.send(:template_name) }

    context 'when template does end with .gitlab-ci.yml' do
      let(:template) { 'my-template.gitlab-ci.yml' }

      it 'returns template name' do
        expect(template_name).to eq('my-template')
      end
    end

    context 'when template is nil' do
      let(:template) { nil }

      it 'returns nil' do
        expect(template_name).to be_nil
      end
    end

    context 'when template does not end with .gitlab-ci.yml' do
      let(:template) { 'my-template' }

      it 'returns nil' do
        expect(template_name).to be_nil
      end
    end
  end

  describe '#expand_context' do
    let(:location) { 'location.yml' }

    subject { template_file.send(:expand_context_attrs) }

    it 'drops all parameters' do
      is_expected.to be_empty
    end
  end
end
