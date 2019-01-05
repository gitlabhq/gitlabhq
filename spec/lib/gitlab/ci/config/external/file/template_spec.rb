# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Config::External::File::Template do
  let(:context) { described_class::Context.new(nil, '12345') }
  let(:template) { 'Auto-DevOps.gitlab-ci.yml' }
  let(:params) { { template: template } }

  subject { described_class.new(params, context) }

  describe '#matching?' do
    context 'when a template is specified' do
      let(:params) { { template: 'some-template' } }

      it 'should return true' do
        expect(subject).to be_matching
      end
    end

    context 'with a missing template' do
      let(:params) { { template: nil } }

      it 'should return false' do
        expect(subject).not_to be_matching
      end
    end

    context 'with a missing template key' do
      let(:params) { {} }

      it 'should return false' do
        expect(subject).not_to be_matching
      end
    end
  end

  describe "#valid?" do
    context 'when is a valid template name' do
      let(:template) { 'Auto-DevOps.gitlab-ci.yml' }

      it 'should return true' do
        expect(subject).to be_valid
      end
    end

    context 'with invalid template name' do
      let(:template) { 'Template.yml' }

      it 'should return false' do
        expect(subject).not_to be_valid
        expect(subject.error_message).to include('Template file `Template.yml` is not a valid location!')
      end
    end

    context 'with a non-existing template' do
      let(:template) { 'I-Do-Not-Have-This-Template.gitlab-ci.yml' }

      it 'should return false' do
        expect(subject).not_to be_valid
        expect(subject.error_message).to include('Included file `I-Do-Not-Have-This-Template.gitlab-ci.yml` is empty or does not exist!')
      end
    end
  end

  describe '#template_name' do
    let(:template_name) { subject.send(:template_name) }

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
end
