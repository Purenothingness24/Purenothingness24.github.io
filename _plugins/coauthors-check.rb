require 'bibtex'

module Jekyll
  # _layouts/bib.liquid links an author's name through _data/coauthors.yml. A misspelled last name or first name
  # there, or an entry for someone no longer in papers.bib, would silently leave names unlinked. Fail the build instead.
  class CoauthorsCheck < Generator
    safe true

    FIELDS = %w[firstname url].freeze
    # The equal-contribution markers that bib.liquid strips from last names before looking them up
    MARKERS = /[*∗†‡§¶‖&^]/

    def generate(site)
      scholar = site.config['scholar']
      bib_path = File.join(site.source, scholar['source'], scholar['bibliography'])
      @data_path = File.join(site.config['data_dir'], 'coauthors.yml')

      authors = BibTeX.open(bib_path, filter: :latex).each_entry.flat_map do |entry|
        next [] unless entry.field?(:author)

        entry.author.map { |name| [lookup_key(name.last), name.first.to_s] }
      end

      coauthors = site.data['coauthors']
      error('expected a mapping of last names to lists of entries') unless coauthors.is_a?(Hash)

      coauthors.each do |last_name, entries|
        error("'#{last_name}': expected a non-empty list of entries") unless entries.is_a?(Array) && !entries.empty?

        entries.each_with_index do |fields, index|
          where = "'#{last_name}', entry #{index + 1}"
          unless fields.is_a?(Hash) && fields.keys.sort == FIELDS
            error("#{where}: expected exactly the fields #{FIELDS.join(', ')}, got #{fields.inspect}")
          end

          first_names = fields['firstname']
          error("#{where}: firstname must be a non-empty list") unless first_names.is_a?(Array) && !first_names.empty?
          error("#{where}: url '#{fields['url']}' is not an http(s) URL") unless fields['url'].to_s.match?(%r{\Ahttps?://\S+\z})
          next if first_names.any? { |first_name| authors.include?([last_name, first_name]) }

          error("#{where}: no author in #{bib_path} has the last name '#{last_name}' and a first name in #{first_names}")
        end
      end
    end

    private

    def lookup_key(last_name)
      CleanString::RemoveAccents.new(string: last_name.to_s.gsub(MARKERS, '').downcase).digest!
    end

    def error(message)
      raise Errors::FatalException, "#{@data_path}: #{message}"
    end
  end
end
