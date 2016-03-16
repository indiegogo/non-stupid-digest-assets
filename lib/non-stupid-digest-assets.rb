require 'sprockets/manifest'

module NonStupidDigestAssets
  @@whitelist = []

  class << self
    def whitelist
      @@whitelist
    end

    def whitelist=(whitelist)
      @@whitelist = whitelist
    end

    def files(files)
      return files if whitelist.empty?
      whitelisted_files(files)
    end

    private

    def whitelisted_files(files)
      files.select do |file, info|
        whitelist.any? do |item|
          item === info['logical_path']
        end
      end
    end
  end

  module CompileWithNonDigest
    def compile *args
      paths = super
      NonStupidDigestAssets.files(files).each do |(digest_path, info)|
        full_digest_path = File.join dir, digest_path
        full_digest_gz_path = "#{full_digest_path}.gz"
        full_non_digest_path = File.join dir, info['logical_path']
        full_non_digest_gz_path = "#{full_non_digest_path}.gz"

        if File.exists? full_digest_path
          FileUtils.copy_file full_digest_path, full_non_digest_path, :preserve_attributes
        end
        if File.exists? full_digest_gz_path
          FileUtils.copy_file full_digest_gz_path, full_non_digest_gz_path, :preserve_attributes
        end
      end
      paths
    end
  end
end

Sprockets::Manifest.send(:prepend, NonStupidDigestAssets::CompileWithNonDigest)
