# based on https://distresssignal.org/busting-css-cache-with-jekyll-md5-hash
# https://gist.github.com/BryanSchuetz/2ee8c115096d7dd98f294362f6a667db
module Jekyll
  module CacheBust
    class CacheDigester
      require 'digest/md5'

      SASS_DIR = '_sass'.freeze

      attr_accessor :file_name, :stylesheet

      def initialize(file_name:, stylesheet: false)
        self.file_name = file_name
        self.stylesheet = stylesheet
      end

      def digest!
        [file_name, '?', Digest::MD5.hexdigest(file_contents)].join
      end

      private

      def file_contents
        stylesheet ? stylesheet_content : File.read(local_file_name)
      end

      # A compiled stylesheet such as assets/css/main.css changes whenever its Sass entry point
      # (assets/css/main.scss) or any partial it can import from _sass/ changes.
      def stylesheet_content
        entry_point = local_file_name.sub(/\.css\z/, '.scss')
        unless File.file?(entry_point)
          raise Errors::FatalException, "cache-bust: #{file_name} has no Sass entry point at #{entry_point}"
        end
        unless File.directory?(SASS_DIR)
          raise Errors::FatalException, "cache-bust: #{SASS_DIR}/ does not exist, so #{file_name} cannot be fingerprinted"
        end

        partials = Dir[File.join(SASS_DIR, '**', '*.scss')].sort
        ([entry_point] + partials).map { |path| File.read(path) }.join
      end

      def local_file_name
        start = file_name.index('assets/')
        raise Errors::FatalException, "cache-bust: #{file_name} is not under assets/" if start.nil?

        file_name[start..]
      end
    end

    def bust_file_cache(file_name)
      CacheDigester.new(file_name: file_name).digest!
    end

    def bust_css_cache(file_name)
      CacheDigester.new(file_name: file_name, stylesheet: true).digest!
    end
  end
end

Liquid::Template.register_filter(Jekyll::CacheBust)
