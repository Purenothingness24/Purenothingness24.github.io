require 'bibtex'

module Jekyll
  # The hidden pitch deck (_pages/pitch/) is rendered from front matter by _layouts/pitch-home.liquid and
  # pitch-slide.liquid, where Liquid renders a misspelled field, a slug without a slide page, or a bib key
  # missing from papers.bib as blank. Fail the build instead, naming the offending page.
  class PitchDeckCheck < Generator
    safe true

    HOME_FIELDS = %w[layout permalink sitemap roles logos groups].freeze
    LOGO_FIELDS = %w[file alt].freeze
    GROUP_FIELDS = %w[name slides].freeze
    SLIDE_REQUIRED_FIELDS = %w[layout permalink sitemap slides].freeze
    SLIDE_OPTIONAL_FIELDS = %w[bib title venue].freeze
    VIDEO_SLIDE_FIELDS = %w[video poster].freeze
    IMAGE_SLIDE_REQUIRED_FIELDS = %w[image ratio background].freeze
    IMAGE_SLIDE_OPTIONAL_FIELDS = %w[ink videos].freeze
    CLIP_REQUIRED_FIELDS = %w[file box].freeze
    CLIP_OPTIONAL_FIELDS = %w[radius outline].freeze
    COLOR = /\A#\h{6}\z/.freeze
    RATIO = %r{\A\d+(\.\d+)? / \d+(\.\d+)?\z}.freeze
    MEDIA_DIR = File.join('assets', 'pitch')
    LOGO_DIR = File.join(MEDIA_DIR, 'logos')

    def generate(site)
      @site = site
      pages = site.pages.group_by { |page| page.data['layout'] }
      homes = pages.fetch('pitch-home', [])
      slides = pages.fetch('pitch-slide', [])
      return if homes.empty? && slides.empty?

      unless homes.size == 1
        raise Errors::FatalException, "Pitch deck: expected one page with layout pitch-home, found #{homes.map(&:path)}"
      end

      home = homes.first
      slide_urls = check_home(home).map { |slug| "#{home.url}#{slug}/" }
      slides_by_url = slides.to_h { |slide| [slide.url, slide] }

      missing = slide_urls - slides_by_url.keys
      error(home, "no pitch-slide page has the permalink #{missing.join(', ')}") unless missing.empty?
      unlisted = slides_by_url.keys - slide_urls
      error(home, "'groups' does not list the slide page(s) at #{unlisted.join(', ')}") unless unlisted.empty?

      scholar = site.config['scholar']
      @bib_path = File.join(site.source, scholar['source'], scholar['bibliography'])
      @bibliography = BibTeX.open(@bib_path)
      slides.each { |slide| check_slide(slide) }
    end

    private

    def check_home(home)
      check_fields(home, home.data, HOME_FIELDS, [], 'front matter')
      error(home, "'roles' must be a non-empty list") unless non_empty_list?(home.data['roles'])

      logos = home.data['logos']
      error(home, "'logos' must be a non-empty list") unless non_empty_list?(logos)
      logos.each_with_index do |logo, index|
        check_fields(home, logo, LOGO_FIELDS, [], "logo #{index + 1}")
        path = File.join(@site.source, LOGO_DIR, logo['file'])
        error(home, "logo '#{logo['file']}' not found at #{path}") unless File.file?(path)
      end

      groups = home.data['groups']
      error(home, "'groups' must be a non-empty list") unless non_empty_list?(groups)
      groups.each_with_index do |group, index|
        check_fields(home, group, GROUP_FIELDS, [], "group #{index + 1}")
        error(home, "group '#{group['name']}': 'slides' must be a non-empty list of slugs") unless non_empty_list?(group['slides'])
      end

      slugs = groups.flat_map { |group| group['slides'] }
      duplicates = slugs.tally.select { |_, count| count > 1 }.keys
      error(home, "slide(s) listed more than once: #{duplicates.join(', ')}") unless duplicates.empty?
      slugs
    end

    def check_slide(page)
      check_fields(page, page.data, SLIDE_REQUIRED_FIELDS, SLIDE_OPTIONAL_FIELDS, 'front matter')

      bib, title = page.data.values_at('bib', 'title')
      error(page, "set exactly one of 'bib' (a papers.bib key) and 'title'") unless bib.nil? ^ title.nil?
      error(page, "bib '#{bib}' is not an entry in #{@bib_path}") if bib && !@bibliography.key?(bib)
      error(page, "'venue' comes from papers.bib when 'bib' is set") if bib && page.data.key?('venue')

      slides = page.data['slides']
      error(page, "'slides' must be a non-empty list") unless non_empty_list?(slides)
      slides.each_with_index do |slide, index|
        where = "slide #{index + 1}"
        error(page, "#{where}: expected a mapping of fields, got #{slide.inspect}") unless slide.is_a?(Hash)

        if slide.key?('video')
          check_fields(page, slide, VIDEO_SLIDE_FIELDS, [], where)
          check_media(page, where, slide['video'], slide['poster'])
        elsif slide.key?('image')
          check_image_slide(page, where, slide)
        else
          error(page, "#{where}: set either 'video' (with 'poster') or 'image'")
        end
      end
    end

    def check_image_slide(page, where, slide)
      check_fields(page, slide, IMAGE_SLIDE_REQUIRED_FIELDS, IMAGE_SLIDE_OPTIONAL_FIELDS, where)
      check_media(page, where, slide['image'])
      error(page, "#{where}: ratio '#{slide['ratio']}' must look like '16 / 9'") unless RATIO.match?(slide['ratio'].to_s)
      %w[background ink].select { |key| slide.key?(key) }.each do |key|
        error(page, "#{where}: #{key} '#{slide[key]}' must be a #rrggbb color") unless COLOR.match?(slide[key].to_s)
      end
      return unless slide.key?('videos')

      error(page, "#{where}: 'videos' must be a non-empty list") unless non_empty_list?(slide['videos'])
      slide['videos'].each_with_index do |clip, index|
        clip_where = "#{where}, video #{index + 1}"
        check_fields(page, clip, CLIP_REQUIRED_FIELDS, CLIP_OPTIONAL_FIELDS, clip_where)
        check_media(page, clip_where, clip['file'])
        error(page, "#{clip_where}: box must be [left, top, width, height] in percent") unless numbers?(clip['box'], 4)
        if clip.key?('radius') && !numbers?(clip['radius'], 2)
          error(page, "#{clip_where}: radius must be [horizontal, vertical] in percent")
        end
        next unless clip.key?('outline')

        color, width = clip['outline']
        unless clip['outline'].is_a?(Array) && clip['outline'].size == 2 && COLOR.match?(color.to_s) && width.is_a?(Numeric)
          error(page, "#{clip_where}: outline must be [#rrggbb, width in percent of the slide width]")
        end
      end
    end

    def check_media(page, where, *files)
      files.each do |file|
        path = File.join(@site.source, MEDIA_DIR, file.to_s)
        error(page, "#{where}: '#{file}' not found at #{path}") unless File.file?(path)
      end
    end

    def numbers?(value, count)
      value.is_a?(Array) && value.size == count && value.all?(Numeric)
    end

    def check_fields(page, fields, required, optional, where)
      error(page, "#{where}: expected a mapping of fields, got #{fields.inspect}") unless fields.is_a?(Hash)

      unknown = fields.keys - required - optional
      unless unknown.empty?
        error(page, "#{where}: unknown field(s) #{unknown.join(', ')}; allowed fields: #{(required + optional).join(', ')}")
      end

      blank = (required | (fields.keys & optional)).select { |field| fields[field].to_s.strip.empty? }
      error(page, "#{where}: missing or blank field(s) #{blank.join(', ')}") unless blank.empty?
      error(page, "set 'sitemap: false' to keep the hidden page out of the sitemap") if fields.key?('sitemap') && fields['sitemap'] != false
    end

    def non_empty_list?(value)
      value.is_a?(Array) && !value.empty?
    end

    def error(page, message)
      raise Errors::FatalException, "#{page.path}: #{message}"
    end
  end
end
