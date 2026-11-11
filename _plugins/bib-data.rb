require 'bibtex'

module Jekyll
  # Exposes the entries of the scholar bibliography to Liquid as site.data.papers[<citation key>], with the fields
  # the hidden pitch deck (_layouts/pitch-deck.liquid) uses for its videos' captions, so the deck uses the same titles
  # and links as the homepage instead of copies of them. LaTeX in the fields is converted like the bibliography's own
  # latex filter does.
  class BibData < Generator
    safe true
    priority :highest

    FIELDS = %w[title website].freeze

    def generate(site)
      scholar = site.config['scholar']
      path = File.join(site.source, scholar['source'], scholar['bibliography'])
      site.data['papers'] = BibTeX.open(path, filter: :latex).each_entry.to_h do |entry|
        fields = FIELDS.select { |field| entry.field?(field.to_sym) }.to_h { |field| [field, entry[field.to_sym].to_s] }
        [entry.key.to_s, fields]
      end
    end
  end
end
