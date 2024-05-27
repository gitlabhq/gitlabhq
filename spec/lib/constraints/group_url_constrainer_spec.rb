# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Constraints::GroupUrlConstrainer do
  let!(:group) { create(:group, path: 'gitlab') }

  describe '#matches?' do
    context 'valid request' do
      let(:request) { build_request(group.path) }

      it { expect(subject.matches?(request)).to be_truthy }
    end

    context 'valid request for nested group' do
      let!(:nested_group) { create(:group, path: 'nested', parent: group) }
      let!(:request) { build_request('gitlab/nested') }

      it { expect(subject.matches?(request)).to be_truthy }
    end

    context 'valid request for nested group with reserved top level name' do
      let!(:nested_group) { create(:group, path: 'api', parent: group) }
      let!(:request) { build_request('gitlab/api') }

      it { expect(subject.matches?(request)).to be_truthy }
    end

    context 'invalid request' do
      let(:request) { build_request('foo') }

      it { expect(subject.matches?(request)).to be_falsey }
    end

    context 'when the request matches a redirect route' do
      context 'for a root group' do
        let!(:redirect_route) { group.redirect_routes.create!(path: 'gitlabb') }

        context 'and is a GET request' do
          let(:request) { build_request(redirect_route.path) }

          it { expect(subject.matches?(request)).to be_truthy }
        end

        context 'and is NOT a GET request' do
          let(:request) { build_request(redirect_route.path, 'POST') }

          it { expect(subject.matches?(request)).to be_falsey }
        end
      end

      context 'for a nested group' do
        let!(:nested_group) { create(:group, path: 'nested', parent: group) }
        let!(:redirect_route) { nested_group.redirect_routes.create!(path: 'gitlabb/nested') }
        let(:request) { build_request(redirect_route.path) }

        it { expect(subject.matches?(request)).to be_truthy }
      end
    end
  end

  def build_request(path, method = 'GET')
    double(:request,
      get?: (method == 'GET'),
      params: { id: path })
  end
end
