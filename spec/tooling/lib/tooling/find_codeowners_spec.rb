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
            entries: %w[whatever entries],
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
        whatever @group
        entries @group
        /dir0/dir1/ @group
        /file @group

      CODEOWNERS
    end
  end

  describe '#load_definitions' do
    before do
      allow(subject).to receive(:load_config).and_return(
        {
          '[Authentication and Authorization]': {
            '@gitlab-org/manage/authentication-and-authorization': {
              allow: {
                keywords: %w[password auth token],
                patterns:
                  %w[
                    /{,ee/}app/**/*%{keyword}*{,/**/*}
                    /{,ee/}config/**/*%{keyword}*{,/**/*}
                    /{,ee/}lib/**/*%{keyword}*{,/**/*}
                  ]
              },
              deny: {
                keywords: %w[*author.* *author_* *authored*],
                patterns: ['%{keyword}']
              }
            }
          },
          '[Compliance]': {
            '@gitlab-org/govern/compliance': {
              entries: %w[
                /ee/app/services/audit_events/build_service.rb
              ],
              allow: {
                patterns: %w[
                  /ee/app/services/audit_events/*
                ]
              }
            }
          }
        }
      )
    end

    it 'expands the allow and deny list with keywords and patterns' do
      group_defintions = subject.load_definitions[:'[Authentication and Authorization]']

      group_defintions.each do |group, definitions|
        expect(definitions[:allow]).to be_an(Array)
        expect(definitions[:deny]).to be_an(Array)
      end
    end

    it 'expands the patterns for the auth group' do
      auth = subject.load_definitions.dig(
        :'[Authentication and Authorization]',
        :'@gitlab-org/manage/authentication-and-authorization')

      expect(auth).to eq(
        allow: %w[
          /{,ee/}app/**/*password*{,/**/*}
          /{,ee/}config/**/*password*{,/**/*}
          /{,ee/}lib/**/*password*{,/**/*}
          /{,ee/}app/**/*auth*{,/**/*}
          /{,ee/}config/**/*auth*{,/**/*}
          /{,ee/}lib/**/*auth*{,/**/*}
          /{,ee/}app/**/*token*{,/**/*}
          /{,ee/}config/**/*token*{,/**/*}
          /{,ee/}lib/**/*token*{,/**/*}
        ],
        deny: %w[
          *author.*
          *author_*
          *authored*
        ]
      )
    end

    it 'retains the array and expands the patterns for the compliance group' do
      compliance = subject.load_definitions.dig(
        :'[Compliance]',
        :'@gitlab-org/govern/compliance')

      expect(compliance).to eq(
        entries: %w[
          /ee/app/services/audit_events/build_service.rb
        ],
        allow: %w[
          /ee/app/services/audit_events/*
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

      expect(File).to receive(:fnmatch?)
        .with("/**/#{pattern}", path, expected_flags)

      subject.path_matches?(pattern, path)
    end
  end

  describe '#normalize_pattern' do
    it 'returns /**/* if the input is *' do
      expect(subject.normalize_pattern('*')).to eq('/**/*')
    end

    it 'prepends /** if the input does not start with /' do
      expect(subject.normalize_pattern('app')).to eq('/**/app')
    end

    it 'returns the pattern if the input starts with /' do
      expect(subject.normalize_pattern('/app')).to eq('/app')
    end

    it 'appends **/* if the input ends with /' do
      expect(subject.normalize_pattern('/app/')).to eq('/app/**/*')
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
