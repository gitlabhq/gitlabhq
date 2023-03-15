# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Tags::CreateService, feature_category: :source_code_management do
  let(:project) { create(:project, :repository) }
  let(:repository) { project.repository }
  let(:user) { create(:user) }
  let(:service) { described_class.new(project, user) }

  describe '#execute' do
    it 'creates the tag and returns success' do
      response = service.execute('v42.42.42', 'master', 'Foo')

      expect(response[:status]).to eq(:success)
      expect(response[:tag]).to be_a Gitlab::Git::Tag
      expect(response[:tag].name).to eq('v42.42.42')
    end

    context 'when target is invalid' do
      it 'returns an error' do
        response = service.execute('v1.1.0', 'foo', 'Foo')

        expect(response[:status]).to eq(:error)
        expect(response[:http_status]).to eq(400)
        expect(response[:message]).to eq('Target foo is invalid')
      end
    end

    context 'when tag_name is empty' do
      it 'returns an error' do
        response = service.execute('', 'foo', 'Foo')

        expect(response[:status]).to eq(:error)
        expect(response[:http_status]).to eq(400)
        expect(response[:message]).to eq('Tag name invalid')
      end
    end

    context 'when target is empty' do
      it 'returns an error' do
        response = service.execute('v1.1.0', '', 'Foo')

        expect(response[:status]).to eq(:error)
        expect(response[:http_status]).to eq(400)
        expect(response[:message]).to eq('Target is empty')
      end
    end

    context 'when tag already exists' do
      it 'returns an error' do
        expect(repository).to receive(:add_tag)
          .with(user, 'v1.1.0', 'master', 'Foo')
          .and_raise(Gitlab::Git::Repository::TagExistsError)

        response = service.execute('v1.1.0', 'master', 'Foo')

        expect(response[:status]).to eq(:error)
        expect(response[:http_status]).to eq(409)
        expect(response[:message]).to eq('Tag v1.1.0 already exists')
      end
    end

    context 'when tag name is invalid' do
      it 'returns an error' do
        response = service.execute('HEAD', 'master', 'Foo')

        expect(response[:status]).to eq(:error)
        expect(response[:http_status]).to eq(400)
        expect(response[:message]).to eq('Tag name invalid')
      end
    end

    context 'when pre-receive hook fails' do
      it 'returns an error' do
        expect(repository).to receive(:add_tag)
          .with(user, 'v1.1.0', 'master', 'Foo')
          .and_raise(Gitlab::Git::PreReceiveError, 'GitLab: something went wrong')

        response = service.execute('v1.1.0', 'master', 'Foo')

        expect(response[:status]).to eq(:error)
        expect(response[:message]).to eq('something went wrong')
      end
    end
  end
end
