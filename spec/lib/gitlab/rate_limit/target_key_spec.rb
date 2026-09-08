# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::RateLimit::TargetKey, feature_category: :rate_limiting do
  using RSpec::Parameterized::TableSyntax

  describe '.for' do
    subject { described_class.for(path) }

    # The first nine rows are the design document's derivation table verbatim.
    where(:path, :expected) do
      '/gitlab-org/gitlab/-/issues/1'          | 'route:gitlab-org/gitlab'
      '/gitlab-org/gitlab.git/info/refs'       | 'route:gitlab-org/gitlab'
      '/api/v4/projects/278964/issues'         | 'project:278964'
      '/api/v4/projects/gitlab-org%2Fgitlab'   | 'route:gitlab-org/gitlab'
      '/api/v4/groups/9970/projects'           | 'group:9970'
      '/api/graphql'                           | nil
      '/dashboard/issues'                      | nil
      '/o/acme/gitlab-org/gitlab/-/issues/1'   | 'route:gitlab-org/gitlab'
      '/o/acme/api/v4/projects/278964/issues'  | 'project:278964'

      # Group and subgroup targets.
      '/gitlab-org/-/issues'                   | 'route:gitlab-org'
      '/gitlab-org'                            | 'route:gitlab-org'
      '/group/sub/project/-/issues'            | 'route:group/sub/project'
      '/group/sub/project'                     | 'route:group/sub/project'
      '/api/v4/groups/gitlab-org%2Fsub'        | 'route:gitlab-org/sub'

      # Wildcard routes collapse to the project rather than minting a key per URL.
      '/ns/proj/blob/master/README.md'         | 'route:ns/proj'
      '/ns/proj/raw/master/a/b/c.txt'          | 'route:ns/proj'
      '/ns/proj/info/lfs/objects/abc123'       | 'route:ns/proj'
      '/ns/proj/gitlab-lfs/objects/abc123'     | 'route:ns/proj'

      # Raw endpoints: the ref, commit and file path never reach the key.
      '/ns/proj/-/raw/master/README.md'        | 'route:ns/proj'
      '/group/sub/proj/-/raw/v1/deep/f.txt'    | 'route:group/sub/proj'
      '/api/v4/projects/278964/repository/files/README.md/raw' | 'project:278964'
      '/api/v4/projects/gl%2Fp/repository/files/a%2Fb.md/raw'  | 'route:gl/p'
      '/api/v4/projects/278964/repository/blobs/abc123/raw'    | 'project:278964'
      '/ns/proj/-/snippets/42/raw'             | 'route:ns/proj'
      # An instance snippet belongs to no namespace.
      '/-/snippets/42/raw'                     | nil

      # A multi-segment wildcard reserves only the whole sequence, so a subgroup may
      # legitimately be called `info` or `environments`...
      '/ns/info/proj/-/issues'                 | 'route:ns/info/proj'
      '/ns/environments/proj'                  | 'route:ns/environments/proj'
      # ...but the full sequence still cuts.
      '/ns/proj/environments/folders/prod'     | 'route:ns/proj'

      # A .git suffix ends the route wherever it appears.
      '/ns/proj.git'                           | 'route:ns/proj'
      '/ns/proj.git/gitlab-lfs/objects/abc123' | 'route:ns/proj'

      # Wiki and design git traffic belongs to the project it hangs off.
      '/ns/proj.wiki.git/info/refs'            | 'route:ns/proj'
      '/ns/proj.design.git/info/refs'          | 'route:ns/proj'
      '/ns/proj.wiki.git'                      | 'route:ns/proj'
      # ...but only over git. `.wiki` is a legal project path, so a project actually
      # named that keeps its own key on a web request.
      '/ns/my.wiki'                            | 'route:ns/my.wiki'
      '/ns/my.wiki/-/issues'                   | 'route:ns/my.wiki'
      '/ns/my.design/-/issues'                 | 'route:ns/my.design'
      # A segment that is nothing but a suffix names no project.
      '/ns/.wiki.git'                          | 'route:ns'
      '/ns/.git'                               | 'route:ns'

      # API ids: nested encoding, and the forms that name nothing.
      '/api/v4/groups/9970'                    | 'group:9970'
      '/api/v4/projects/gitlab-org%2Fsub%2Fp'  | 'route:gitlab-org/sub/p'
      '/api/v4/projects/'                      | nil
      '/api/v4/projects'                       | nil
      '/api/v4/jobs/request'                   | nil

      # Decoded as a path, not a form value: a literal + survives rather than
      # becoming a space
      '/api/v4/projects/a+b'                   | 'route:a+b'
      '/api/v4/projects/a%2Bb'                 | 'route:a+b'

      # An empty segment ends the route rather than being absorbed into it.
      '/ns//proj'                              | 'route:ns'

      # Case folds onto one target, since the route lookup is case-insensitive.
      '/GitLab-Org/GitLab/-/issues/1'          | 'route:gitlab-org/gitlab'
      '/GitLab-Org/GitLab.git/info/refs'       | 'route:gitlab-org/gitlab'
      '/api/v4/projects/GitLab-Org%2FGitLab'   | 'route:gitlab-org/gitlab'
      '/api/v4/groups/GitLab-Org'              | 'route:gitlab-org'
      # A numeric id is not a path, so it is never folded.
      '/api/v4/projects/278964'                | 'project:278964'

      # Percent-decoding a validly encoded path can still yield invalid bytes.
      '/api/v4/projects/%FF'                   | nil
      '/api/v4/projects/ok%FFbad'              | nil

      # Container Registry and Dependency Proxy derive nothing: `v2` is a top-level
      # route, so the namespace in the path is never reached.
      '/v2/group/project/manifests/latest'     | nil
      '/v2/group/dep_proxy/containers/a/manifests/latest' | nil
      '/v2/virtual_registries/container/7/manifests/latest' | nil
      '/jwt/auth'                              | nil

      # Top-level routes name no namespace, with or without the org scope.
      '/explore'                               | nil
      '/api/v4/internal/allowed'               | nil
      '/-/health'                              | nil
      '/o/acme/dashboard/issues'               | nil
      '/o/acme'                                | nil
      '/'                                      | nil
      ''                                       | nil
    end

    with_them do
      it { is_expected.to eq(expected) }
    end

    # The suffixes are derived from GlRepository, so a new repo type starts being
    # stripped without a change here. Pin the set the rows above were written against.
    it 'strips every repository type suffix GlRepository defines' do
      expect(Gitlab::GlRepository.types.values.map(&:path_suffix)).to contain_exactly(
        '', '.wiki', '', '.design'
      )
    end

    it 'accepts a path exactly at the maximum depth' do
      at_boundary = Array.new(Namespace::NUMBER_OF_ANCESTORS_ALLOWED + 2) { |i| "s#{i}" }

      expect(described_class.for("/#{at_boundary.join('/')}")).to eq("route:#{at_boundary.join('/')}")
    end

    it 'rejects a path deeper than a root namespace, its subgroups and a project' do
      too_deep = "/#{Array.new(Namespace::NUMBER_OF_ANCESTORS_ALLOWED + 3) { |i| "s#{i}" }.join('/')}"

      expect(described_class.for(too_deep)).to be_nil
    end

    it 'accepts an API path id exactly at the maximum depth' do
      at_boundary = Array.new(Namespace::NUMBER_OF_ANCESTORS_ALLOWED + 2) { |i| "s#{i}" }

      expect(described_class.for("/api/v4/projects/#{at_boundary.join('%2F')}"))
        .to eq("route:#{at_boundary.join('/')}")
    end

    it 'caps an API path id at the same depth as a derived route' do
      too_deep = Array.new(Namespace::NUMBER_OF_ANCESTORS_ALLOWED + 3) { |i| "s#{i}" }.join('%2F')

      expect(described_class.for("/api/v4/projects/#{too_deep}")).to be_nil
    end

    context 'when the instance is mounted at a relative url root' do
      before do
        stub_config_setting(relative_url_root: '/gitlab')
      end

      where(:relative_path, :expected_key) do
        '/gitlab/gitlab-org/gitlab/-/issues/1'         | 'route:gitlab-org/gitlab'
        '/gitlab/api/v4/projects/278964/issues'        | 'project:278964'
        '/gitlab/o/acme/gitlab-org/gitlab'             | 'route:gitlab-org/gitlab'
        '/gitlab/explore'                              | nil
        '/gitlab'                                      | nil
      end

      with_them do
        it { expect(described_class.for(relative_path)).to eq(expected_key) }
      end
    end

    it 'returns nil for a path with malformed bytes rather than raising' do
      expect(described_class.for("/gitlab-org/gitlab\xFF/-/issues/1")).to be_nil
    end

    it 'returns nil for a non-String, so no request object can be passed in' do
      expect(described_class.for(nil)).to be_nil
      expect(described_class.for(:'/gitlab-org/gitlab')).to be_nil
    end
  end

  describe 'the key grammar' do
    it 'names an API project target by project id, which is not a namespace id' do
      expect(described_class.for('/api/v4/projects/278964')).to eq('project:278964')
    end

    it 'names an API group target by group id, which is already a namespace id' do
      expect(described_class.for('/api/v4/groups/9970')).to eq('group:9970')
    end

    it 'names every other target by lowercased full path, group and project alike' do
      expect(described_class.for('/GitLab-Org')).to eq('route:gitlab-org')
      expect(described_class.for('/GitLab-Org/GitLab')).to eq('route:gitlab-org/gitlab')
    end

    it 'returns nil when the path names no namespace, not when a lookup would fail' do
      expect(described_class.for('/api/graphql')).to be_nil
      expect(described_class.for('/explore')).to be_nil
      expect(described_class.for('/nonexistent-group/nonexistent-project')).to eq(
        'route:nonexistent-group/nonexistent-project'
      )
    end

    it 'starts every route identifier with the root namespace path' do
      derived = [
        described_class.for('/gitlab-org/sub/proj/-/issues'),
        described_class.for('/gitlab-org/sub/proj.wiki.git/info/refs'),
        described_class.for('/api/v4/projects/gitlab-org%2Fsub%2Fproj'),
        described_class.for('/o/acme/gitlab-org/sub/proj')
      ]

      expect(derived).to all(start_with('route:gitlab-org/'))
    end
  end

  # The module takes a path rather than a request, so Rack::Request#params is
  # unreachable by construction. This pins that signature: the derivation cannot grow
  # a body-parsing dependency without changing its arity.
  describe 'the public signature' do
    it 'accepts exactly one positional argument' do
      expect(described_class.method(:for).arity).to eq(1)
    end

    it 'never touches params on an API path' do
      request = Rack::Request.new(Rack::MockRequest.env_for('/api/v4/projects/278964/issues'))

      expect(request).not_to receive(:params)

      expect(described_class.for(request.path)).to eq('project:278964')
    end
  end
end
