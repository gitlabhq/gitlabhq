require 'spec_helper'

describe ConstrainerHelper, lib: true do
  include ConstrainerHelper

  describe '#extract_resource_path' do
    it { expect(extract_resource_path('/gitlab/')).to eq('gitlab') }
    it { expect(extract_resource_path('///gitlab//')).to eq('gitlab') }
    it { expect(extract_resource_path('/gitlab.atom')).to eq('gitlab') }

    context 'relative url' do
      before do
        allow(Gitlab::Application.config).to receive(:relative_url_root) { '/gitlab' }
      end

      it { expect(extract_resource_path('/gitlab/foo')).to eq('foo') }
      it { expect(extract_resource_path('/foo/bar')).to eq('foo/bar') }
    end
  end
end
