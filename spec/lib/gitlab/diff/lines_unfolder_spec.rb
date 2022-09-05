# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Diff::LinesUnfolder do
  let(:raw_diff) do
    <<-DIFF.strip_heredoc
      @@ -7,9 +7,6 @@
           "tags": ["devel", "development", "nightly"],
           "desktop-file-name-prefix": "(Development) ",
           "finish-args": [
      -        "--share=ipc", "--socket=x11",
      -        "--socket=wayland",
      -        "--talk-name=org.gnome.OnlineAccounts",
               "--talk-name=org.freedesktop.Tracker1",
               "--filesystem=home",
               "--talk-name=org.gtk.vfs", "--talk-name=org.gtk.vfs.*",
      @@ -62,7 +59,7 @@
               },
               {
                   "name": "gnome-desktop",
      -            "config-opts": ["--disable-debug-tools", "--disable-udev"],
      +            "config-opts": ["--disable-debug-tools", "--disable-"],
                   "sources": [
                       {
                           "type": "git",
      @@ -83,11 +80,6 @@
                   "buildsystem": "meson",
                   "builddir": true,
                   "name": "nautilus",
      -            "config-opts": [
      -                "-Denable-desktop=false",
      -                "-Denable-selinux=false",
      -                "--libdir=/app/lib"
      -            ],
                   "sources": [
                       {
                           "type": "git",
    DIFF
  end

  let(:raw_old_blob) do
    <<-BLOB.strip_heredoc
      {
          "app-id": "org.gnome.Nautilus",
          "runtime": "org.gnome.Platform",
          "runtime-version": "master",
          "sdk": "org.gnome.Sdk",
          "command": "nautilus",
          "tags": ["devel", "development", "nightly"],
          "desktop-file-name-prefix": "(Development) ",
          "finish-args": [
              "--share=ipc", "--socket=x11",
              "--socket=wayland",
              "--talk-name=org.gnome.OnlineAccounts",
              "--talk-name=org.freedesktop.Tracker1",
              "--filesystem=home",
              "--talk-name=org.gtk.vfs", "--talk-name=org.gtk.vfs.*",
              "--filesystem=xdg-run/dconf", "--filesystem=~/.config/dconf:ro",
              "--talk-name=ca.desrt.dconf", "--env=DCONF_USER_CONFIG_DIR=.config/dconf"
          ],
          "cleanup": [ "/include", "/share/bash-completion" ],
          "modules": [
              {
                  "name": "exiv2",
                  "sources": [
                      {
                          "type": "archive",
                          "url": "http://exiv2.org/builds/exiv2-0.26-trunk.tar.gz",
                          "sha256": "c75e3c4a0811bf700d92c82319373b7a825a2331c12b8b37d41eb58e4f18eafb"
                      },
                      {
                          "type": "shell",
                          "commands": [
                              "cp -f /usr/share/gnu-config/config.sub ./config/",
                              "cp -f /usr/share/gnu-config/config.guess ./config/"
                          ]
                      }
                  ]
              },
              {
                  "name": "gexiv2",
                  "config-opts": [ "--disable-introspection" ],
                  "sources": [
                      {
                          "type": "git",
                          "url": "https://git.gnome.org/browse/gexiv2"
                      }
                  ]
              },
              {
                  "name": "tracker",
                  "cleanup": [ "/bin", "/etc", "/libexec" ],
                  "config-opts": [ "--disable-miner-apps", "--disable-static",
                                   "--disable-tracker-extract", "--disable-tracker-needle",
                                   "--disable-tracker-preferences", "--disable-artwork",
                                   "--disable-tracker-writeback", "--disable-miner-user-guides",
                                   "--with-bash-completion-dir=no" ],
                  "sources": [
                      {
                          "type": "git",
                          "url": "https://git.gnome.org/browse/tracker"
                      }
                  ]
              },
              {
                  "name": "gnome-desktop",
                  "config-opts": ["--disable-debug-tools", "--disable-udev"],
                  "sources": [
                      {
                          "type": "git",
                          "url": "https://git.gnome.org/browse/gnome-desktop"
                      }
                  ]
              },
              {
                  "name": "gnome-autoar",
                  "sources": [
                      {
                          "type": "git",
                          "url": "https://git.gnome.org/browse/gnome-autoar"
                      }
                  ]
              },
              {
                  "buildsystem": "meson",
                  "builddir": true,
                  "name": "nautilus",
                  "config-opts": [
                      "-Denable-desktop=false",
                      "-Denable-selinux=false",
                      "--libdir=/app/lib"
                  ],
                  "sources": [
                      {
                          "type": "git",
                          "url": "https://gitlab.gnome.org/GNOME/nautilus.git"
                      }
                  ]
              }
          ]
      },
      {
          "app-id": "foo",
          "runtime": "foo",
          "runtime-version": "foo",
          "sdk": "foo",
          "command": "foo",
          "tags": ["foo", "bar", "kux"],
          "desktop-file-name-prefix": "(Foo) ",
          {
            "buildsystem": "meson",
            "builddir": true,
            "name": "nautilus",
            "sources": [
              {
                "type": "git",
                "url": "https://gitlab.gnome.org/GNOME/nautilus.git"
              }
            ]
          }
      },
      {
          "app-id": "foo",
          "runtime": "foo",
          "runtime-version": "foo",
          "sdk": "foo",
          "command": "foo",
          "tags": ["foo", "bar", "kux"],
          "desktop-file-name-prefix": "(Foo) ",
          {
            "buildsystem": "meson",
            "builddir": true,
            "name": "nautilus",
            "sources": [
              {
                "type": "git",
                "url": "https://gitlab.gnome.org/GNOME/nautilus.git"
              }
            ]
          }
      }
    BLOB
  end

  let(:project) { create(:project) }

  let(:old_blob) { Blob.decorate(Gitlab::Git::Blob.new(data: raw_old_blob, size: 10)) }

  let(:diff) do
    Gitlab::Git::Diff.new({ diff: raw_diff,
                            new_path: "build-aux/flatpak/org.gnome.Nautilus.json",
                            old_path: "build-aux/flatpak/org.gnome.Nautilus.json",
                            a_mode: "100644",
                            b_mode: "100644",
                            new_file: false,
                            renamed_file: false,
                            deleted_file: false,
                            too_large: false })
  end

  let(:diff_file) do
    Gitlab::Diff::File.new(diff, repository: project.repository)
  end

  before do
    allow(old_blob).to receive(:load_all_data!)
    allow(diff_file).to receive(:old_blob) { old_blob }
  end

  subject { described_class.new(diff_file, position) }

  context 'position requires a middle expansion and new match lines' do
    let(:position) do
      build(:text_diff_position, old_line: 43, new_line: 40)
    end

    context 'old_line is an invalid number' do
      let(:position) do
        build(:text_diff_position, old_line: "foo", new_line: 40)
      end

      it 'fails gracefully' do
        expect(subject.unfolded_diff_lines).to be_nil
      end
    end

    context 'blob lines' do
      let(:expected_blob_lines) do
        [[40, 40, "             \"config-opts\": [ \"--disable-introspection\" ],"],
         [41, 41, "             \"sources\": ["],
         [42, 42, "                 {"],
         [43, 43, "                     \"type\": \"git\","],
         [44, 44, "                     \"url\": \"https://git.gnome.org/browse/gexiv2\""],
         [45, 45, "                 }"],
         [46, 46, "             ]"]]
      end

      it 'returns the extracted blob lines correctly' do
        extracted_lines = subject.blob_lines

        expect(extracted_lines.size).to eq(7)

        extracted_lines.each_with_index do |line, i|
          expect([line.old_line, line.new_line, line.text]).to eq(expected_blob_lines[i])
        end
      end
    end

    context 'diff lines' do
      let(:expected_diff_lines) do
        [[7, 7, "@@ -7,9 +7,6 @@"],
         [7, 7, "     \"tags\": [\"devel\", \"development\", \"nightly\"],"],
         [8, 8, "     \"desktop-file-name-prefix\": \"(Development) \","],
         [9, 9, "     \"finish-args\": ["],
         [10, 10, "-        \"--share=ipc\", \"--socket=x11\","],
         [11, 10, "-        \"--socket=wayland\","],
         [12, 10, "-        \"--talk-name=org.gnome.OnlineAccounts\","],
         [13, 10, "         \"--talk-name=org.freedesktop.Tracker1\","],
         [14, 11, "         \"--filesystem=home\","],
         [15, 12, "         \"--talk-name=org.gtk.vfs\", \"--talk-name=org.gtk.vfs.*\","],

         # New match line
         [40, 37, "@@ -40,7+37,7 @@"],

         # Injected blob lines
         [40, 37, "             \"config-opts\": [ \"--disable-introspection\" ],"],
         [41, 38, "             \"sources\": ["],
         [42, 39, "                 {"],
         [43, 40, "                     \"type\": \"git\","], # comment
         [44, 41, "                     \"url\": \"https://git.gnome.org/browse/gexiv2\""],
         [45, 42, "                 }"],
         [46, 43, "             ]"],
         # end

         # Second match line
         [62, 59, "@@ -62,7+59,7 @@"],

         [62, 59, "         },"],
         [63, 60, "         {"],
         [64, 61, "             \"name\": \"gnome-desktop\","],
         [65, 62, "-            \"config-opts\": [\"--disable-debug-tools\", \"--disable-udev\"],"],
         [66, 62, "+            \"config-opts\": [\"--disable-debug-tools\", \"--disable-\"],"],
         [66, 63, "             \"sources\": ["],
         [67, 64, "                 {"],
         [68, 65, "                     \"type\": \"git\","],
         [83, 80, "@@ -83,11 +80,6 @@"],
         [83, 80, "             \"buildsystem\": \"meson\","],
         [84, 81, "             \"builddir\": true,"],
         [85, 82, "             \"name\": \"nautilus\","],
         [86, 83, "-            \"config-opts\": ["],
         [87, 83, "-                \"-Denable-desktop=false\","],
         [88, 83, "-                \"-Denable-selinux=false\","],
         [89, 83, "-                \"--libdir=/app/lib\""],
         [90, 83, "-            ],"],
         [91, 83, "             \"sources\": ["],
         [92, 84, "                 {"],
         [93, 85, "                     \"type\": \"git\","]]
      end

      it 'return merge of blob lines with diff lines correctly' do
        new_diff_lines = subject.unfolded_diff_lines

        expected_diff_lines.each_with_index do |expected_line, i|
          line = new_diff_lines[i]

          expect([line.old_pos, line.new_pos, line.text]).to eq(expected_line)
        end
      end

      it 'merged lines have correct line codes' do
        new_diff_lines = subject.unfolded_diff_lines

        new_diff_lines.each_with_index do |line, i|
          old_pos = expected_diff_lines[i][0]
          new_pos = expected_diff_lines[i][1]

          unless line.type == 'match'
            expect(line.line_code).to eq(Gitlab::Git.diff_line_code(diff_file.file_path, new_pos, old_pos))
          end
        end
      end
    end
  end

  context 'position requires a middle expansion and no top match line' do
    let(:position) do
      build(:text_diff_position, old_line: 16, new_line: 17)
    end

    context 'blob lines' do
      let(:expected_blob_lines) do
        [[16, 16, "         \"--filesystem=xdg-run/dconf\", \"--filesystem=~/.config/dconf:ro\","],
         [17, 17, "         \"--talk-name=ca.desrt.dconf\", \"--env=DCONF_USER_CONFIG_DIR=.config/dconf\""],
         [18, 18, "     ],"],
         [19, 19, "     \"cleanup\": [ \"/include\", \"/share/bash-completion\" ],"]]
      end

      it 'returns the extracted blob lines correctly' do
        extracted_lines = subject.blob_lines

        expect(extracted_lines.size).to eq(4)

        extracted_lines.each_with_index do |line, i|
          expect([line.old_line, line.new_line, line.text]).to eq(expected_blob_lines[i])
        end
      end
    end

    context 'diff lines' do
      let(:expected_diff_lines) do
        [[7, 7, "@@ -7,9 +7,6 @@"],
         [7, 7, "     \"tags\": [\"devel\", \"development\", \"nightly\"],"],
         [8, 8, "     \"desktop-file-name-prefix\": \"(Development) \","],
         [9, 9, "     \"finish-args\": ["],
         [10, 10, "-        \"--share=ipc\", \"--socket=x11\","],
         [11, 10, "-        \"--socket=wayland\","],
         [12, 10, "-        \"--talk-name=org.gnome.OnlineAccounts\","],
         [13, 10, "         \"--talk-name=org.freedesktop.Tracker1\","],
         [14, 11, "         \"--filesystem=home\","],
         [15, 12, "         \"--talk-name=org.gtk.vfs\", \"--talk-name=org.gtk.vfs.*\","],
         # No new match needed

         # Injected blob lines
         [16, 13, "         \"--filesystem=xdg-run/dconf\", \"--filesystem=~/.config/dconf:ro\","],
         [17, 14, "         \"--talk-name=ca.desrt.dconf\", \"--env=DCONF_USER_CONFIG_DIR=.config/dconf\""],
         [18, 15, "     ],"],
         [19, 16, "     \"cleanup\": [ \"/include\", \"/share/bash-completion\" ],"],
         # end

         # Second match line
         [62, 59, "@@ -62,4+59,4 @@"],

         [62, 59, "         },"],
         [63, 60, "         {"],
         [64, 61, "             \"name\": \"gnome-desktop\","],
         [65, 62, "-            \"config-opts\": [\"--disable-debug-tools\", \"--disable-udev\"],"],
         [66, 62, "+            \"config-opts\": [\"--disable-debug-tools\", \"--disable-\"],"],
         [66, 63, "             \"sources\": ["],
         [67, 64, "                 {"],
         [68, 65, "                     \"type\": \"git\","],
         [83, 80, "@@ -83,11 +80,6 @@"],
         [83, 80, "             \"buildsystem\": \"meson\","],
         [84, 81, "             \"builddir\": true,"],
         [85, 82, "             \"name\": \"nautilus\","],
         [86, 83, "-            \"config-opts\": ["],
         [87, 83, "-                \"-Denable-desktop=false\","],
         [88, 83, "-                \"-Denable-selinux=false\","],
         [89, 83, "-                \"--libdir=/app/lib\""],
         [90, 83, "-            ],"],
         [91, 83, "             \"sources\": ["],
         [92, 84, "                 {"],
         [93, 85, "                     \"type\": \"git\","]]
      end

      it 'return merge of blob lines with diff lines correctly' do
        new_diff_lines = subject.unfolded_diff_lines

        expected_diff_lines.each_with_index do |expected_line, i|
          line = new_diff_lines[i]

          expect([line.old_pos, line.new_pos, line.text]).to eq(expected_line)
        end
      end

      it 'merged lines have correct line codes' do
        new_diff_lines = subject.unfolded_diff_lines

        new_diff_lines.each_with_index do |line, i|
          old_pos = expected_diff_lines[i][0]
          new_pos = expected_diff_lines[i][1]

          unless line.type == 'match'
            expect(line.line_code).to eq(Gitlab::Git.diff_line_code(diff_file.file_path, new_pos, old_pos))
          end
        end
      end
    end
  end

  context 'position requires a middle expansion and no bottom match line' do
    let(:position) do
      build(:text_diff_position, old_line: 82, new_line: 79)
    end

    context 'blob lines' do
      let(:expected_blob_lines) do
        [[79, 79, "                 }"],
         [80, 80, "             ]"],
         [81, 81, "         },"],
         [82, 82, "         {"]]
      end

      it 'returns the extracted blob lines correctly' do
        extracted_lines = subject.blob_lines

        expect(extracted_lines.size).to eq(4)

        extracted_lines.each_with_index do |line, i|
          expect([line.old_line, line.new_line, line.text]).to eq(expected_blob_lines[i])
        end
      end
    end

    context 'diff lines' do
      let(:expected_diff_lines) do
        [[7, 7, "@@ -7,9 +7,6 @@"],
         [7, 7, "     \"tags\": [\"devel\", \"development\", \"nightly\"],"],
         [8, 8, "     \"desktop-file-name-prefix\": \"(Development) \","],
         [9, 9, "     \"finish-args\": ["],
         [10, 10, "-        \"--share=ipc\", \"--socket=x11\","],
         [11, 10, "-        \"--socket=wayland\","],
         [12, 10, "-        \"--talk-name=org.gnome.OnlineAccounts\","],
         [13, 10, "         \"--talk-name=org.freedesktop.Tracker1\","],
         [14, 11, "         \"--filesystem=home\","],
         [15, 12, "         \"--talk-name=org.gtk.vfs\", \"--talk-name=org.gtk.vfs.*\","],
         [62, 59, "@@ -62,7 +59,7 @@"],
         [62, 59, "         },"],
         [63, 60, "         {"],
         [64, 61, "             \"name\": \"gnome-desktop\","],
         [65, 62, "-            \"config-opts\": [\"--disable-debug-tools\", \"--disable-udev\"],"],
         [66, 62, "+            \"config-opts\": [\"--disable-debug-tools\", \"--disable-\"],"],
         [66, 63, "             \"sources\": ["],
         [67, 64, "                 {"],
         [68, 65, "                     \"type\": \"git\","],

         # New top match line
         [79, 76, "@@ -79,4+76,4 @@"],

         # Injected blob lines
         [79, 76, "                 }"],
         [80, 77, "             ]"],
         [81, 78, "         },"],
         [82, 79, "         {"],
         # end

         # No new second match line
         [83, 80, "             \"buildsystem\": \"meson\","],
         [84, 81, "             \"builddir\": true,"],
         [85, 82, "             \"name\": \"nautilus\","],
         [86, 83, "-            \"config-opts\": ["],
         [87, 83, "-                \"-Denable-desktop=false\","],
         [88, 83, "-                \"-Denable-selinux=false\","],
         [89, 83, "-                \"--libdir=/app/lib\""],
         [90, 83, "-            ],"],
         [91, 83, "             \"sources\": ["],
         [92, 84, "                 {"],
         [93, 85, "                     \"type\": \"git\","]]
      end

      it 'return merge of blob lines with diff lines correctly' do
        new_diff_lines = subject.unfolded_diff_lines

        expected_diff_lines.each_with_index do |expected_line, i|
          line = new_diff_lines[i]

          expect([line.old_pos, line.new_pos, line.text]).to eq(expected_line)
        end
      end

      it 'merged lines have correct line codes' do
        new_diff_lines = subject.unfolded_diff_lines

        new_diff_lines.each_with_index do |line, i|
          old_pos = expected_diff_lines[i][0]
          new_pos = expected_diff_lines[i][1]

          unless line.type == 'match'
            expect(line.line_code).to eq(Gitlab::Git.diff_line_code(diff_file.file_path, new_pos, old_pos))
          end
        end
      end
    end
  end

  context 'position requires a short top expansion' do
    let(:position) do
      build(:text_diff_position, old_line: 6, new_line: 6)
    end

    context 'blob lines' do
      let(:expected_blob_lines) do
        [[3, 3, "     \"runtime\": \"org.gnome.Platform\","],
         [4, 4, "     \"runtime-version\": \"master\","],
         [5, 5, "     \"sdk\": \"org.gnome.Sdk\","],
         [6, 6, "     \"command\": \"nautilus\","]]
      end

      it 'returns the extracted blob lines correctly' do
        extracted_lines = subject.blob_lines

        expect(extracted_lines.size).to eq(4)

        extracted_lines.each_with_index do |line, i|
          expect([line.old_line, line.new_line, line.text]).to eq(expected_blob_lines[i])
        end
      end
    end

    context 'diff lines' do
      let(:expected_diff_lines) do
        # New match line
        [[3, 3, "@@ -3,4+3,4 @@"],

         # Injected blob lines
         [3, 3, "     \"runtime\": \"org.gnome.Platform\","],
         [4, 4, "     \"runtime-version\": \"master\","],
         [5, 5, "     \"sdk\": \"org.gnome.Sdk\","],
         [6, 6, "     \"command\": \"nautilus\","],
         # end
         [7, 7, "     \"tags\": [\"devel\", \"development\", \"nightly\"],"],
         [8, 8, "     \"desktop-file-name-prefix\": \"(Development) \","],
         [9, 9, "     \"finish-args\": ["],
         [10, 10, "-        \"--share=ipc\", \"--socket=x11\","],
         [11, 10, "-        \"--socket=wayland\","],
         [12, 10, "-        \"--talk-name=org.gnome.OnlineAccounts\","],
         [13, 10, "         \"--talk-name=org.freedesktop.Tracker1\","],
         [14, 11, "         \"--filesystem=home\","],
         [15, 12, "         \"--talk-name=org.gtk.vfs\", \"--talk-name=org.gtk.vfs.*\","],
         [62, 59, "@@ -62,7 +59,7 @@"],
         [62, 59, "         },"],
         [63, 60, "         {"],
         [64, 61, "             \"name\": \"gnome-desktop\","],
         [65, 62, "-            \"config-opts\": [\"--disable-debug-tools\", \"--disable-udev\"],"],
         [66, 62, "+            \"config-opts\": [\"--disable-debug-tools\", \"--disable-\"],"],
         [66, 63, "             \"sources\": ["],
         [67, 64, "                 {"],
         [68, 65, "                     \"type\": \"git\","],
         [83, 80, "@@ -83,11 +80,6 @@"],
         [83, 80, "             \"buildsystem\": \"meson\","],
         [84, 81, "             \"builddir\": true,"],
         [85, 82, "             \"name\": \"nautilus\","],
         [86, 83, "-            \"config-opts\": ["],
         [87, 83, "-                \"-Denable-desktop=false\","],
         [88, 83, "-                \"-Denable-selinux=false\","],
         [89, 83, "-                \"--libdir=/app/lib\""],
         [90, 83, "-            ],"],
         [91, 83, "             \"sources\": ["],
         [92, 84, "                 {"],
         [93, 85, "                     \"type\": \"git\","]]
      end

      it 'return merge of blob lines with diff lines correctly' do
        new_diff_lines = subject.unfolded_diff_lines

        expected_diff_lines.each_with_index do |expected_line, i|
          line = new_diff_lines[i]

          expect([line.old_pos, line.new_pos, line.text]).to eq(expected_line)
        end
      end

      it 'merged lines have correct line codes' do
        new_diff_lines = subject.unfolded_diff_lines

        new_diff_lines.each_with_index do |line, i|
          old_pos = expected_diff_lines[i][0]
          new_pos = expected_diff_lines[i][1]

          unless line.type == 'match'
            expect(line.line_code).to eq(Gitlab::Git.diff_line_code(diff_file.file_path, new_pos, old_pos))
          end
        end
      end
    end
  end

  context 'position sits between two match lines (no expasion needed)' do
    let(:position) do
      build(:text_diff_position, old_line: 64, new_line: 61)
    end

    context 'diff lines' do
      it 'returns nil' do
        expect(subject.unfolded_diff_lines).to be_nil
      end
    end
  end

  context 'position requires bottom expansion and new match lines' do
    let(:position) do
      build(:text_diff_position, old_line: 107, new_line: 99)
    end

    context 'blob lines' do
      let(:expected_blob_lines) do
        [[104, 104, "     \"sdk\": \"foo\","],
         [105, 105, "     \"command\": \"foo\","],
         [106, 106, "     \"tags\": [\"foo\", \"bar\", \"kux\"],"],
         [107, 107, "     \"desktop-file-name-prefix\": \"(Foo) \","],
         [108, 108, "     {"],
         [109, 109, "       \"buildsystem\": \"meson\","],
         [110, 110, "       \"builddir\": true,"]]
      end

      it 'returns the extracted blob lines correctly' do
        extracted_lines = subject.blob_lines

        expect(extracted_lines.size).to eq(7)

        extracted_lines.each_with_index do |line, i|
          expect([line.old_line, line.new_line, line.text]).to eq(expected_blob_lines[i])
        end
      end
    end

    context 'diff lines' do
      let(:expected_diff_lines) do
        [[7, 7, "@@ -7,9 +7,6 @@"],
         [7, 7, "     \"tags\": [\"devel\", \"development\", \"nightly\"],"],
         [8, 8, "     \"desktop-file-name-prefix\": \"(Development) \","],
         [9, 9, "     \"finish-args\": ["],
         [10, 10, "-        \"--share=ipc\", \"--socket=x11\","],
         [11, 10, "-        \"--socket=wayland\","],
         [12, 10, "-        \"--talk-name=org.gnome.OnlineAccounts\","],
         [13, 10, "         \"--talk-name=org.freedesktop.Tracker1\","],
         [14, 11, "         \"--filesystem=home\","],
         [15, 12, "         \"--talk-name=org.gtk.vfs\", \"--talk-name=org.gtk.vfs.*\","],
         [62, 59, "@@ -62,7 +59,7 @@"],
         [62, 59, "         },"],
         [63, 60, "         {"],
         [64, 61, "             \"name\": \"gnome-desktop\","],
         [65, 62, "-            \"config-opts\": [\"--disable-debug-tools\", \"--disable-udev\"],"],
         [66, 62, "+            \"config-opts\": [\"--disable-debug-tools\", \"--disable-\"],"],
         [66, 63, "             \"sources\": ["],
         [67, 64, "                 {"],
         [68, 65, "                     \"type\": \"git\","],
         [83, 80, "@@ -83,11 +80,6 @@"],
         [83, 80, "             \"buildsystem\": \"meson\","],
         [84, 81, "             \"builddir\": true,"],
         [85, 82, "             \"name\": \"nautilus\","],
         [86, 83, "-            \"config-opts\": ["],
         [87, 83, "-                \"-Denable-desktop=false\","],
         [88, 83, "-                \"-Denable-selinux=false\","],
         [89, 83, "-                \"--libdir=/app/lib\""],
         [90, 83, "-            ],"],
         [91, 83, "             \"sources\": ["],
         [92, 84, "                 {"],
         [93, 85, "                     \"type\": \"git\","],
         # New match line
         [104, 96, "@@ -104,7+96,7 @@"],

         # Injected blob lines
         [104, 96, "     \"sdk\": \"foo\","],
         [105, 97, "     \"command\": \"foo\","],
         [106, 98, "     \"tags\": [\"foo\", \"bar\", \"kux\"],"],
         [107, 99, "     \"desktop-file-name-prefix\": \"(Foo) \","],
         [108, 100, "     {"],
         [109, 101, "       \"buildsystem\": \"meson\","],
         [110, 102, "       \"builddir\": true,"]]
        # end
      end

      it 'return merge of blob lines with diff lines correctly' do
        new_diff_lines = subject.unfolded_diff_lines

        expected_diff_lines.each_with_index do |expected_line, i|
          line = new_diff_lines[i]

          expect([line.old_pos, line.new_pos, line.text]).to eq(expected_line)
        end
      end

      it 'merged lines have correct line codes' do
        new_diff_lines = subject.unfolded_diff_lines

        new_diff_lines.each_with_index do |line, i|
          old_pos = expected_diff_lines[i][0]
          new_pos = expected_diff_lines[i][1]

          unless line.type == 'match'
            expect(line.line_code).to eq(Gitlab::Git.diff_line_code(diff_file.file_path, new_pos, old_pos))
          end
        end
      end
    end

    context 'position requires bottom expansion and no new match line' do
      let(:position) do
        build(:text_diff_position, old_line: 95, new_line: 87)
      end

      context 'blob lines' do
        let(:expected_blob_lines) do
          [[94, 94, "                     \"url\": \"https://gitlab.gnome.org/GNOME/nautilus.git\""],
           [95, 95, "                 }"],
           [96, 96, "             ]"],
           [97, 97, "         }"],
           [98, 98, "     ]"]]
        end

        it 'returns the extracted blob lines correctly' do
          extracted_lines = subject.blob_lines

          expect(extracted_lines.size).to eq(5)

          extracted_lines.each_with_index do |line, i|
            expect([line.old_line, line.new_line, line.text]).to eq(expected_blob_lines[i])
          end
        end
      end

      context 'diff lines' do
        let(:expected_diff_lines) do
          [[7, 7, "@@ -7,9 +7,6 @@"],
           [7, 7, "     \"tags\": [\"devel\", \"development\", \"nightly\"],"],
           [8, 8, "     \"desktop-file-name-prefix\": \"(Development) \","],
           [9, 9, "     \"finish-args\": ["],
           [10, 10, "-        \"--share=ipc\", \"--socket=x11\","],
           [11, 10, "-        \"--socket=wayland\","],
           [12, 10, "-        \"--talk-name=org.gnome.OnlineAccounts\","],
           [13, 10, "         \"--talk-name=org.freedesktop.Tracker1\","],
           [14, 11, "         \"--filesystem=home\","],
           [15, 12, "         \"--talk-name=org.gtk.vfs\", \"--talk-name=org.gtk.vfs.*\","],
           [62, 59, "@@ -62,7 +59,7 @@"],
           [62, 59, "         },"],
           [63, 60, "         {"],
           [64, 61, "             \"name\": \"gnome-desktop\","],
           [65, 62, "-            \"config-opts\": [\"--disable-debug-tools\", \"--disable-udev\"],"],
           [66, 62, "+            \"config-opts\": [\"--disable-debug-tools\", \"--disable-\"],"],
           [66, 63, "             \"sources\": ["],
           [67, 64, "                 {"],
           [68, 65, "                     \"type\": \"git\","],
           [83, 80, "@@ -83,11 +80,6 @@"],
           [83, 80, "             \"buildsystem\": \"meson\","],
           [84, 81, "             \"builddir\": true,"],
           [85, 82, "             \"name\": \"nautilus\","],
           [86, 83, "-            \"config-opts\": ["],
           [87, 83, "-                \"-Denable-desktop=false\","],
           [88, 83, "-                \"-Denable-selinux=false\","],
           [89, 83, "-                \"--libdir=/app/lib\""],
           [90, 83, "-            ],"],
           [91, 83, "             \"sources\": ["],
           [92, 84, "                 {"],
           [93, 85, "                     \"type\": \"git\","],
           # No new match line

           # Injected blob lines
           [94, 86, "                     \"url\": \"https://gitlab.gnome.org/GNOME/nautilus.git\""],
           [95, 87, "                 }"],
           [96, 88, "             ]"],
           [97, 89, "         }"],
           [98, 90, "     ]"]]
          # end
        end

        it 'return merge of blob lines with diff lines correctly' do
          new_diff_lines = subject.unfolded_diff_lines

          expected_diff_lines.each_with_index do |expected_line, i|
            line = new_diff_lines[i]

            expect([line.old_pos, line.new_pos, line.text]).to eq(expected_line)
          end
        end

        it 'merged lines have correct line codes' do
          new_diff_lines = subject.unfolded_diff_lines

          new_diff_lines.each_with_index do |line, i|
            old_pos = expected_diff_lines[i][0]
            new_pos = expected_diff_lines[i][1]

            unless line.type == 'match'
              expect(line.line_code).to eq(Gitlab::Git.diff_line_code(diff_file.file_path, new_pos, old_pos))
            end
          end
        end
      end
    end
  end

  context 'positioned on an image' do
    let(:position) { build(:image_diff_position) }

    before do
      allow(old_blob).to receive(:binary?).and_return(binary?)
    end

    context 'diff file is not text' do
      let(:binary?) { true }

      it 'returns nil' do
        expect(subject.unfolded_diff_lines).to be_nil
      end
    end

    context 'diff file is text' do
      let(:binary?) { false }

      it 'returns nil' do
        expect(subject.unfolded_diff_lines).to be_nil
      end
    end
  end
end
