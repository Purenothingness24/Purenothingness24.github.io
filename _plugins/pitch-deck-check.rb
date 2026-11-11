module Jekyll
  # The hidden pitch deck (_pages/pitch/index.md) is rendered from its front matter by _layouts/pitch-deck.liquid,
  # where Liquid renders a misspelled field, a missing file or an unknown bib key as a blank or broken tile. Fail the
  # build instead, naming the offending slide and project. Runs after BibData (_plugins/bib-data.rb) fills
  # site.data.papers.
  class PitchDeckCheck < Generator
    safe true
    priority :low

    DECK_FIELDS = %w[layout permalink sitemap roles logos slides].freeze
    LOGO_FIELDS = %w[file alt].freeze
    PROJECTS_SLIDE_FIELDS = %w[title projects].freeze
    ABOUT_SLIDE_FIELDS = %w[about].freeze
    PROJECT_REQUIRED_FIELDS = %w[bib venue video poster].freeze
    PROJECT_OPTIONAL_FIELDS = %w[name first_author].freeze
    PAPER_FIELDS = %w[title].freeze
    URL = %r{\Ahttps?://\S+\z}.freeze
    MEDIA_DIR = File.join('assets', 'pitch')
    LOGO_DIR = File.join(MEDIA_DIR, 'logos')

    def generate(site)
      @site = site
      decks = site.pages.select { |page| page.data['layout'] == 'pitch-deck' }
      return if decks.empty?

      raise Errors::FatalException, "Pitch deck: expected one page with layout pitch-deck, found #{decks.map(&:path)}" unless decks.size == 1

      @page = decks.first
      check_fields(@page.data, DECK_FIELDS, [], 'front matter')
      error("set 'sitemap: false' to keep the hidden deck out of the sitemap") unless @page.data['sitemap'] == false
      error("'roles' must be a non-empty list") unless non_empty_list?(@page.data['roles'])
      check_logos(@page.data['logos'])

      slides = @page.data['slides']
      error("'slides' must be a non-empty list") unless non_empty_list?(slides)
      slides.each_with_index { |slide, index| check_slide(slide, "slide #{index + 1}") }
      about_count = slides.count { |slide| slide.is_a?(Hash) && slide.key?('about') }
      error("expected exactly one slide with 'about: true', found #{about_count}") unless about_count == 1
    end

    private

    def check_logos(logos)
      error("'logos' must be a non-empty list") unless non_empty_list?(logos)
      logos.each_with_index do |logo, index|
        check_fields(logo, LOGO_FIELDS, [], "logo #{index + 1}")
        path = File.join(@site.source, LOGO_DIR, logo['file'])
        error("logo '#{logo['file']}' not found at #{path}") unless File.file?(path)
      end
    end

    def check_slide(slide, where)
      error("#{where}: expected a mapping of fields, got #{slide.inspect}") unless slide.is_a?(Hash)

      if slide.key?('about')
        check_fields(slide, ABOUT_SLIDE_FIELDS, [], where)
        error("#{where}: 'about' must be true") unless slide['about'] == true
        return
      end

      check_fields(slide, PROJECTS_SLIDE_FIELDS, [], where)
      projects = slide['projects']
      error("#{where}: 'projects' must be a non-empty list") unless non_empty_list?(projects)
      projects.each_with_index do |project, index|
        project_where = "#{where} ('#{slide['title']}'), project #{index + 1}"
        check_fields(project, PROJECT_REQUIRED_FIELDS, PROJECT_OPTIONAL_FIELDS, project_where)
        check_paper(project['bib'], project_where)
        error("#{project_where}: first_author must be true when set") if project.key?('first_author') && project['first_author'] != true
        %w[video poster].each do |field|
          path = File.join(@site.source, MEDIA_DIR, project[field].to_s)
          error("#{project_where}: #{field} '#{project[field]}' not found at #{path}") unless File.file?(path)
        end
      end
    end

    def check_paper(key, where)
      paper = @site.data.fetch('papers').fetch(key.to_s) { error("#{where}: bib '#{key}' is not an entry in the scholar bibliography") }
      missing = PAPER_FIELDS.reject { |field| paper[field].to_s.strip.length.positive? }
      error("#{where}: bib entry '#{key}' has no #{missing.join(' or ')}, which the slide shows") unless missing.empty?
      return unless paper.key?('website') && !URL.match?(paper['website'])

      error("#{where}: bib entry '#{key}' has website '#{paper['website']}', which is not an http(s) URL")
    end

    def check_fields(fields, required, optional, where)
      error("#{where}: expected a mapping of fields, got #{fields.inspect}") unless fields.is_a?(Hash)

      unknown = fields.keys - required - optional
      unless unknown.empty?
        error("#{where}: unknown field(s) #{unknown.join(', ')}; allowed fields: #{(required + optional).join(', ')}")
      end

      blank = (required | (fields.keys & optional)).select { |field| fields[field].to_s.strip.empty? }
      error("#{where}: missing or blank field(s) #{blank.join(', ')}") unless blank.empty?
    end

    def non_empty_list?(value)
      value.is_a?(Array) && !value.empty?
    end

    def error(message)
      raise Errors::FatalException, "#{@page.path}: #{message}"
    end
  end
end
