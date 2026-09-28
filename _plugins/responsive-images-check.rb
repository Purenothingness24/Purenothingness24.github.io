module Jekyll
  # _includes/figure.liquid points each image's <source srcset> at the resized WebP copies that
  # jekyll-imagemagick writes into the built site. That plugin only logs an error when `convert` fails
  # or ImageMagick is not installed, and the pages would then ship WebP URLs that 404.
  module ResponsiveImagesCheck
    SRCSET = /\ssrcset="([^"]*)"/

    def self.missing_webp(site)
      (site.pages + site.documents).select { |item| item.output_ext == '.html' }.flat_map do |item|
        item.output.to_s.scan(SRCSET).flatten
            .flat_map { |srcset| srcset.split(',').map { |candidate| candidate.split.first } }
            .compact
            .select { |url| url.end_with?('.webp') && !url.include?('://') }
            .reject { |url| File.file?(File.join(site.dest, url.delete_prefix(site.baseurl.to_s))) }
            .map { |url| "#{item.relative_path}: #{url}" }
      end.uniq
    end
  end

  Hooks.register :site, :post_write do |site|
    missing = ResponsiveImagesCheck.missing_webp(site)
    next if missing.empty?

    raise Errors::FatalException,
          "#{missing.size} WebP image(s) referenced by a srcset are missing from #{site.dest} " \
          "(is ImageMagick installed?):\n  #{missing.join("\n  ")}"
  end
end
