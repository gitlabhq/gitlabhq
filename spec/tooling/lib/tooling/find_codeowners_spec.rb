# frozen_string_literal: true

require_relative '../../../../tooling/lib/tooling/find_codeowners'

RSpec.describe Tooling::FindCodeowners do
  let(:subject) { described_class.new }
  let(:root) { File.expand_path('../../fixtures/find_codeowners', __dir__) }

  describe '#execute' do
    before do
      allow(subject).to receive(:load_config).and_return(
        '[Section name]': {
          '@group': {
            allow: {
              keywords: %w[dir0 file],
              patterns: ['/%{keyword}/**/*', '/%{keyword}']
            },
            deny: {
              keywords: %w[file0],
              patterns: ['**/%{keyword}']
            }
          }
        }
      )
    end

    it 'prints CODEOWNERS as configured' do
      expect do
        Dir.chdir(root) do
          subject.execute
        end
      end.to output(<<~CODEOWNERS).to_stdout
        [Section name]
        /dir0/dir1 @group
        /file @group
      CODEOWNERS
    end
  end

  describe '#load_definitions' do
    it 'expands the allow and deny list with keywords and patterns' do
      subject.load_definitions.each do |section, group_defintions|
        group_defintions.each do |group, definitions|
          expect(definitions[:allow]).to be_an(Array)
          expect(definitions[:deny]).to be_an(Array)
        end
      end
    end

    it 'expands the auth group' do
      auth = subject.load_definitions.dig(
        :'[Authentication and Authorization]',
        :'@gitlab-org/manage/authentication-and-authorization')

      expect(auth).to eq(
        allow: %w[
          /{,ee/}app/**/*password*{/**/*,}
          /{,ee/}config/**/*password*{/**/*,}
          /{,ee/}lib/**/*password*{/**/*,}
          /{,ee/}app/**/*auth*{/**/*,}
          /{,ee/}config/**/*auth*{/**/*,}
          /{,ee/}lib/**/*auth*{/**/*,}
          /{,ee/}app/**/*token*{/**/*,}
          /{,ee/}config/**/*token*{/**/*,}
          /{,ee/}lib/**/*token*{/**/*,}
        ],
        deny: %w[
          **/*author.*{/**/*,}
          **/*author_*{/**/*,}
          **/*authored*{/**/*,}
          **/*authoring*{/**/*,}
          **/*.png*{/**/*,}
          **/*.svg*{/**/*,}
          **/*deploy_token*{/**/*,}
          **/*runner{,s}_token*{/**/*,}
          **/*job_token*{/**/*,}
          **/*autocomplete_tokens*{/**/*,}
          **/*dast_site_token*{/**/*,}
          **/*reset_prometheus_token*{/**/*,}
          **/*reset_registration_token*{/**/*,}
          **/*runners_registration_token*{/**/*,}
          **/*terraform_registry_token*{/**/*,}
          **/*tokenizer*{/**/*,}
          **/*filtered_search*{/**/*,}
          **/*/alert_management/*{/**/*,}
          **/*/analytics/*{/**/*,}
          **/*/bitbucket/*{/**/*,}
          **/*/clusters/*{/**/*,}
          **/*/clusters_list/*{/**/*,}
          **/*/dast/*{/**/*,}
          **/*/dast_profiles/*{/**/*,}
          **/*/dast_site_tokens/*{/**/*,}
          **/*/dast_site_validation/*{/**/*,}
          **/*/dependency_proxy/*{/**/*,}
          **/*/error_tracking/*{/**/*,}
          **/*/google_api/*{/**/*,}
          **/*/google_cloud/*{/**/*,}
          **/*/jira_connect/*{/**/*,}
          **/*/kubernetes/*{/**/*,}
          **/*/protected_environments/*{/**/*,}
          **/*/config/feature_flags/development/jira_connect_*{/**/*,}
          **/*/config/metrics/*{/**/*,}
          **/*/app/controllers/groups/dependency_proxy_auth_controller.rb*{/**/*,}
          **/*/app/finders/ci/auth_job_finder.rb*{/**/*,}
          **/*/ee/config/metrics/*{/**/*,}
          **/*/lib/gitlab/conan_token.rb*{/**/*,}
        ]
      )
    end
  end

  describe '#load_config' do
    it 'loads the config with symbolized keys' do
      config = subject.load_config

      expect_hash_keys_to_be_symbols(config)
    end

    context 'when YAML has safe_load_file' do
      before do
        allow(YAML).to receive(:respond_to?).with(:safe_load_file).and_return(true)
      end

      it 'calls safe_load_file' do
        expect(YAML).to receive(:safe_load_file)

        subject.load_config
      end
    end

    context 'when YAML does not have safe_load_file' do
      before do
        allow(YAML).to receive(:respond_to?).with(:safe_load_file).and_return(false)
      end

      it 'calls load_file' do
        expect(YAML).to receive(:safe_load)

        subject.load_config
      end
    end

    def expect_hash_keys_to_be_symbols(object)
      if object.is_a?(Hash)
        object.each do |key, value|
          expect(key).to be_a(Symbol)

          expect_hash_keys_to_be_symbols(value)
        end
      end
    end
  end

  describe '#path_matches?' do
    let(:pattern) { 'pattern' }
    let(:path) { 'path' }

    it 'passes flags we are expecting to File.fnmatch?' do
      expected_flags =
        ::File::FNM_DOTMATCH | ::File::FNM_PATHNAME | ::File::FNM_EXTGLOB

      expect(File).to receive(:fnmatch?).with(pattern, path, expected_flags)

      subject.path_matches?(pattern, path)
    end
  end

  describe '#consolidate_paths' do
    before do
      allow(subject).to receive(:find_dir_maxdepth_1).and_return(<<~LINES)
        dir
        dir/0
        dir/2
        dir/3
        dir/1
      LINES
    end

    context 'when the directory has the same number of entries' do
      let(:input_paths) { %W[dir/0\n dir/1\n dir/2\n dir/3\n] }

      it 'consolidates into the directory' do
        paths = subject.consolidate_paths(input_paths)

        expect(paths).to eq(["dir\n"])
      end
    end

    context 'when the directory has different number of entries' do
      let(:input_paths) { %W[dir/0\n dir/1\n dir/2\n] }

      it 'returns the original paths' do
        paths = subject.consolidate_paths(input_paths)

        expect(paths).to eq(input_paths)
      end
    end
  end
end
