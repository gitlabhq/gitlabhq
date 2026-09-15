# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Mfe::VendorFile, feature_category: :compliance_management do
  using RSpec::Parameterized::TableSyntax

  let(:config_path) { Rails.root.join(described_class::CONFIG_PATH) }

  before do
    described_class.reset!
  end

  after do
    described_class.reset!
  end

  def stub_vendor_file(contents)
    stub_file_read(config_path, content: contents)
  end

  describe '.entries' do
    context 'with a valid pin' do
      before do
        stub_vendor_file(<<~YAML)
          apps:
            - name: duo_chat
              version: 0.4.0
              sha: #{'a' * 64}
        YAML
      end

      it 'returns parsed entries', :aggregate_failures do
        entries = described_class.entries

        expect(entries.size).to eq(1)
        expect(entries.first).to have_attributes(
          name: 'duo_chat',
          version: '0.4.0',
          sha: 'a' * 64
        )
      end

      it 'memoizes the result' do
        described_class.entries

        expect(File).not_to receive(:read)

        described_class.entries
      end

      it 'returns frozen entries so callers cannot corrupt the shared pins', :aggregate_failures do
        entries = described_class.entries

        expect { entries.first.version = '9.9.9' }.to raise_error(FrozenError)
        expect { entries.first.name << '!' }.to raise_error(FrozenError)
        expect { entries << :extra }.to raise_error(FrozenError)
      end
    end

    context 'with multiple pins' do
      before do
        stub_vendor_file(<<~YAML)
          apps:
            - name: duo_chat
              version: 0.4.0
              sha: #{'a' * 64}
            - name: another_app
              version: 1.2.3
              sha: #{'b' * 64}
        YAML
      end

      it 'returns every entry' do
        expect(described_class.entries.map(&:name)).to eq(%w[duo_chat another_app])
      end
    end

    context 'with a hyphenated name' do
      before do
        stub_vendor_file(<<~YAML)
          apps:
            - name: gitlab-mfe-mock
              version: 1.0.0
              sha: #{'a' * 64}
        YAML
      end

      it 'accepts hyphens in the name' do
        expect(described_class.entries.map(&:name)).to eq(['gitlab-mfe-mock'])
      end
    end

    context 'when apps is empty' do
      before do
        stub_vendor_file("apps: []\n")
      end

      specify { expect(described_class.entries).to eq([]) }
    end

    context 'when apps is missing' do
      before do
        stub_vendor_file("# only comments\n")
      end

      specify { expect(described_class.entries).to eq([]) }
    end

    context 'when apps is not a list' do
      before do
        stub_vendor_file("apps: duo_chat\n")
      end

      it 'fails loudly with an actionable error' do
        expect { described_class.entries }
          .to raise_error(described_class::InvalidEntryError, /'apps' must be a list/)
      end
    end

    context 'when the file root is not a map' do
      before do
        stub_vendor_file("- duo_chat\n")
      end

      it 'fails loudly instead of treating it as a no-op' do
        expect { described_class.entries }
          .to raise_error(described_class::InvalidEntryError, /root must be a map/)
      end
    end

    context 'when the non-map root uses YAML aliases' do
      before do
        stub_vendor_file("- &pin duo_chat\n- *pin\n")
      end

      it 'fails loudly instead of raising a raw Psych error' do
        expect { described_class.entries }
          .to raise_error(described_class::InvalidEntryError, /root must be a map/)
      end
    end

    context 'when an apps element is not a map' do
      before do
        stub_vendor_file(<<~YAML)
          apps:
            - duo_chat
        YAML
      end

      it 'fails loudly with an actionable error' do
        expect { described_class.entries }
          .to raise_error(described_class::InvalidEntryError, /expected a map, got "duo_chat"/)
      end
    end

    context 'when two pins share the same name' do
      before do
        stub_vendor_file(<<~YAML)
          apps:
            - name: duo_chat
              version: 1.0.0
              sha: #{'a' * 64}
            - name: duo_chat
              version: 2.0.0
              sha: #{'b' * 64}
        YAML
      end

      it 'rejects the ambiguous vendor file' do
        expect { described_class.entries }
          .to raise_error(described_class::InvalidEntryError, /duplicate MFE pins: duo_chat/)
      end
    end

    context 'with an invalid name' do
      where(:name) { ['Duo-Chat', '-leading-hyphen', '_leading_underscore', 'has space', 'UPPER'] }

      with_them do
        before do
          stub_vendor_file(<<~YAML)
            apps:
              - name: "#{name}"
                version: 0.4.0
                sha: #{'a' * 64}
          YAML
        end

        it 'raises an actionable error' do
          expect { described_class.entries }
            .to raise_error(described_class::InvalidEntryError, /invalid MFE name/)
        end
      end
    end

    context 'with an invalid version' do
      where(:version) { ['0.4', '0.4.0.1', 'v0.4.0', '1.x.0', ''] }

      with_them do
        before do
          stub_vendor_file(<<~YAML)
            apps:
              - name: duo_chat
                version: "#{version}"
                sha: #{'a' * 64}
          YAML
        end

        it 'raises an actionable error' do
          expect { described_class.entries }
            .to raise_error(described_class::InvalidEntryError, /must be MAJOR\.MINOR\.PATCH/)
        end
      end
    end

    context 'with an invalid sha' do
      where(:sha) { ['a' * 63, 'a' * 65, "#{'a' * 63}X", 'A' * 64, ''] }

      with_them do
        before do
          stub_vendor_file(<<~YAML)
            apps:
              - name: duo_chat
                version: 0.4.0
                sha: "#{sha}"
          YAML
        end

        it 'raises an actionable error' do
          expect { described_class.entries }
            .to raise_error(described_class::InvalidEntryError, /must be 64 lowercase hex characters/)
        end
      end
    end

    context 'when the file is not valid YAML' do
      before do
        stub_vendor_file("apps:\n  - name: [unterminated\n")
      end

      it 'fails loudly' do
        expect { described_class.entries }
          .to raise_error(described_class::InvalidEntryError, /could not parse vendor file/)
      end
    end

    context 'when the pin file is missing' do
      before do
        stub_file_read(config_path, error: Errno::ENOENT)
      end

      it 'fails loudly instead of raising a raw filesystem error' do
        expect { described_class.entries }
          .to raise_error(described_class::InvalidEntryError, /could not read vendor file/)
      end
    end

    context 'with the committed vendor file (no stubs)' do
      it 'parses cleanly, guarding the hand-edited pin file against corruption' do
        expect(described_class.entries)
          .to all(have_attributes(name: be_present, version: be_present, sha: be_present))
      end
    end
  end
end
