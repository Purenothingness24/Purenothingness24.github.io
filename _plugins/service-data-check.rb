module Jekyll
  # _includes/service.liquid renders _data/service.yml, and Liquid renders a missing or misspelled
  # field as blank. Fail the build instead, naming the offending section or entry.
  class ServiceDataCheck < Generator
    safe true

    SECTION_FIELDS = %w[title entries].freeze
    REQUIRED_FIELDS = %w[role name dates image image_alt].freeze
    OPTIONAL_FIELDS = %w[url org image_fit entries].freeze
    IMAGE_FITS = %w[contain cover].freeze
    IMAGE_DIR = File.join('assets', 'img', 'service')

    def generate(site)
      @site = site
      sections = site.data['service']
      error('expected a list of sections') unless sections.is_a?(Array)

      sections.each_with_index do |section, index|
        check_fields(section, SECTION_FIELDS, [], "section #{index + 1}")
        check_entries(section['entries'], "section '#{section['title']}'", nested: false)
      end
    end

    private

    def check_entries(entries, where, nested:)
      error("#{where}: 'entries' must be a non-empty list") unless entries.is_a?(Array) && !entries.empty?

      optional = nested ? OPTIONAL_FIELDS - ['entries'] : OPTIONAL_FIELDS
      entries.each_with_index do |entry, index|
        check_fields(entry, REQUIRED_FIELDS, optional, "#{where}, entry #{index + 1}")
        label = "#{where}, entry '#{entry['role']}, #{entry['name']}'"

        if entry.key?('image_fit') && !IMAGE_FITS.include?(entry['image_fit'])
          error("#{label}: image_fit is '#{entry['image_fit']}', expected one of: #{IMAGE_FITS.join(', ')}")
        end

        image_path = File.join(@site.source, IMAGE_DIR, entry['image'].to_s)
        error("#{label}: image '#{entry['image']}' not found at #{image_path}") unless File.file?(image_path)

        check_entries(entry['entries'], label, nested: true) if entry.key?('entries')
      end
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

    def error(message)
      raise Errors::FatalException, "#{File.join(@site.config['data_dir'], 'service.yml')}: #{message}"
    end
  end
end
