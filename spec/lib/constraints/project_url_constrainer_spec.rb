# frozen_string_literal: true

require 'spec_helper'

describe Constraints::ProjectUrlConstrainer do
  let!(:project) { create(:project) }
  let!(:namespace) { project.namespace }

  describe '#matches?' do
    context 'valid request' do
      let(:request) { build_request(namespace.full_path, project.path) }

      it { expect(subject.matches?(request)).to be_truthy }
    end

    context 'invalid request' do
      context "project id ending with .git" do
        let(:request) { build_request(namespace.full_path, project.path + '.git') }

        it { expect(subject.matches?(request)).to be_falsey }
      end
    end
  end

  def build_request(namespace, project)
    double(:request, params: { namespace_id: namespace, id: project })
  end
end
