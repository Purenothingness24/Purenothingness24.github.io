require 'bibtex'

module Jekyll
  # The Research and Projects pages list papers.bib entries by `category`, so an
  # entry with a missing or unknown category would appear on neither page.
  class BibCategoryCheck < Generator
    safe true

    CATEGORIES = %w[research project].freeze

    def generate(site)
      scholar = site.config['scholar']
      path = File.join(site.source, scholar['source'], scholar['bibliography'])

      BibTeX.open(path).each_entry do |entry|
        category = entry[:category].to_s
        next if CATEGORIES.include?(category)

        raise Errors::FatalException,
              "#{path}: entry '#{entry.key}' has category '#{category}', expected one of: #{CATEGORIES.join(', ')}"
      end
    end
  end
end
