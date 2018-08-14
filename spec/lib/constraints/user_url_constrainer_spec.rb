require 'spec_helper'

describe Constraints::UserUrlConstrainer do
  let!(:user) { create(:user, username: 'dz') }

  describe '#matches?' do
    context 'valid request' do
      let(:request) { build_request(user.username) }

      it { expect(subject.matches?(request)).to be_truthy }
    end

    context 'invalid request' do
      let(:request) { build_request('foo') }

      it { expect(subject.matches?(request)).to be_falsey }
    end

    context 'when the request matches a redirect route' do
      let(:old_project_path) { 'old_project_path' }
      let!(:redirect_route) { user.namespace.redirect_routes.create!(path: 'foo') }

      context 'and is a GET request' do
        let(:request) { build_request(redirect_route.path) }
        it { expect(subject.matches?(request)).to be_truthy }
      end

      context 'and is NOT a GET request' do
        let(:request) { build_request(redirect_route.path, 'POST') }
        it { expect(subject.matches?(request)).to be_falsey }
      end
    end
  end

  def build_request(username, method = 'GET')
    double(:request,
      'get?': (method == 'GET'),
      params: { username: username })
  end
end
