require 'fpm/cookery/source_handler/template'

module FPM
  module Cookery
    class SourceHandler
      class Svn < FPM::Cookery::SourceHandler::Template

        CHECKSUM = false
        NAME = :svn

        def fetch(config = {})
          # TODO(lusis) - implement some caching using 'svn info'?
          Dir.chdir(cachedir) do
            svn(url, local_path)
          end
          local_path
        end

        def extract(config = {})
          Dir.chdir(builddir) do
            safesystem('cp', '-Rp', local_path, '.')
            (builddir/extracted_source).to_s
          end
        end

        private
        def svn(url, path)
          extra_args = []

          extra_args << '--ignore-externals' if !options[:externals]

          [:username, :password].each do |opt|
            if options.key? opt
              extra_args << "--#{opt}" << options[opt]
            end
          end

          revision = options[:revision] || 'HEAD'

          safesystem('svn', 'export', '--force', *extra_args, '-q', '-r', revision, url, path)
        end

        def extracted_source
          entries = Dir['*'].select {|dir| File.directory?(dir) }

          case entries.size
          when 0
            raise "Empty checkout! (#{local_path})"
          when 1
            entries.first
          else
            # Use the directory that was created last.
            dir = entries.sort do |a, b|
              File.stat(a).ctime <=> File.stat(b).ctime
            end.last

            if File.exist?(dir)
              dir
            else
              raise "Could not find source directory for #{local_path.basename}"
            end
          end
        end
      end
    end
  end
end
