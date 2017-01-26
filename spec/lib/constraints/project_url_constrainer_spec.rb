require 'spec_helper'

describe ProjectUrlConstrainer, lib: true do
  let!(:project) { create(:empty_project) }
  let!(:namespace) { project.namespace }

  describe '#matches?' do
    context 'valid request' do
      let(:request) { build_request(namespace.path, project.path) }

      it { expect(subject.matches?(request)).to be_truthy }
    end

    context 'invalid request' do
      context "non-existing project" do
        let(:request) { build_request('foo', 'bar') }

        it { expect(subject.matches?(request)).to be_falsey }
      end

      context "project id ending with .git" do
        let(:request) { build_request(namespace.path, project.path + '.git') }

        it { expect(subject.matches?(request)).to be_falsey }
      end
    end
  end

  def build_request(namespace, project)
    double(:request, params: { namespace_id: namespace, id: project })
  end
end
