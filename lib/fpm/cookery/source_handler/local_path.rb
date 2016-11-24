require 'fpm/cookery/source_handler/template'
require 'fpm/cookery/log'
require 'fileutils'

module FPM
  module Cookery
    class SourceHandler
      class LocalPath < FPM::Cookery::SourceHandler::Curl
        CHECKSUM = false
        NAME = :local_path

        def fetch_repo(source, dest)
          git_patch = cachedir/'working.patch'

          safesystem "rm -rf #{dest}"
          submodules = nil
          Dir.chdir(source.to_s) do
            submodules = `grep path .gitmodules | sed 's/.*= //'` if File.file?('.gitmodules')
            Log.info "Running: git clone --shared #{source} #{dest}"
            safesystem "git clone --shared #{source} #{dest}"
            safesystem "git add -A"
            safesystem "git diff --cached --binary > #{git_patch}"
          end
          Log.info "Patching source working directory changes"
          # Only patch if the patch if non-empty
          unless File.zero?("#{git_patch}")
            Dir.chdir("#{dest}") do
              safesystem "git apply --whitespace=nowarn #{git_patch}"
              safesystem "rm #{git_patch}"
            end
          end

          unless submodules == nil
            submodules.each_line do |submodule|
              Log.info "Copying submodule #{submodule}"
              submodule = submodule.chomp
              fetch_repo(source/submodule, dest/submodule)
            end
          end
        end

        def fetch(config = {})
          if File.directory?(source.path+"/.git")
            dest = cachedir/Path.new(source.path).basename
            Log.info "Source is Git repo, using clone method."
            fetch_repo(Path.new(source.path), dest)
          elsif local_path.exist?
            Log.info "Using cached file #{local_path}"
          else
            Log.info "Copying #{source.path} to cache"
            FileUtils.cp_r(source.path, cachedir)
          end
          Log.info "local_path:#{local_path}"
          local_path
        end
      end
    end
  end
end
