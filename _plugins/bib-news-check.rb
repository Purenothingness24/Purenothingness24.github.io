require 'bibtex'

module Jekyll
  # bib.liquid renders an entry's `news` field as link buttons: "Label | URL" pairs separated by ", ", e.g.
  # news={Singapore HTX | https://example.com/a, NVIDIA GTC 2026 | https://example.com/b}. Liquid would render a
  # malformed pair as a blank or broken button, so fail the build instead.
  class BibNewsCheck < Generator
    safe true

    URL = %r{\Ahttps?://[^[:space:]]+\z}

    def generate(site)
      scholar = site.config['scholar']
      path = File.join(site.source, scholar['source'], scholar['bibliography'])
      filters = scholar['bibtex_filters'] || []

      BibTeX.open(path).each_entry do |entry|
        next unless entry.field?(:news)

        @where = "#{path}: entry '#{entry.key}'"
        error('news is blank') if entry[:news].to_s.strip.empty?

        # jekyll-scholar passes every field through the bibtex_filters before bib.liquid sees it, and the latex
        # filter rewrites URL characters such as -- and ~.
        raw = pairs(entry[:news].to_s)
        rendered = pairs(entry[:news].convert(*filters).to_s)
        unless rendered.size == raw.size
          error("the bibtex_filters (#{filters.join(', ')}) turn #{raw.size} news item(s) into #{rendered.size}")
        end

        rendered.zip(raw).each_with_index do |(pair, raw_pair), index|
          label, url = pair
          unless pair.size == 2 && !label.empty? && URL.match?(url)
            error("news item #{index + 1} is '#{pair.join(' | ')}', expected 'Label | http(s)://URL'")
          end
          next if url == raw_pair[1]

          error("the bibtex_filters (#{filters.join(', ')}) rewrite the URL of news item '#{label}' from " \
                "'#{raw_pair[1]}' to '#{url}'; percent-encode the characters they change")
        end

        labels = rendered.map(&:first)
        duplicates = labels.select { |label| labels.count(label) > 1 }.uniq
        error("news labels must be unique, found #{duplicates.join(', ')} more than once") unless duplicates.empty?
      end
    end

    private

    # The same parsing as bib.liquid, except that a trailing empty item is kept, so a stray ", " is an error too
    def pairs(value)
      value.gsub(/\r?\n/, '').split(', ', -1).map { |item| item.split('|', -1).map(&:strip) }
    end

    def error(message)
      raise Errors::FatalException, "#{@where}: #{message}"
    end
  end
end
