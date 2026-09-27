require 'bibtex'

module Jekyll
  # bib.liquid builds an entry's preview player from `preview_videos` (comma-separated clips) and
  # `preview_poster`, both paths under assets/video/. A missing file would render a broken player.
  class BibPreviewVideosCheck < Generator
    safe true

    def generate(site)
      scholar = site.config['scholar']
      path = File.join(site.source, scholar['source'], scholar['bibliography'])

      BibTeX.open(path).each_entry do |entry|
        videos = entry[:preview_videos].to_s.split(',').map(&:strip)
        poster = entry[:preview_poster].to_s.strip
        next if videos.empty? && poster.empty?

        if videos.empty? || poster.empty?
          raise Errors::FatalException,
                "#{path}: entry '#{entry.key}' must set both preview_videos and preview_poster"
        end

        (videos + [poster]).each do |file|
          file_path = File.join(site.source, 'assets', 'video', file)
          next if File.file?(file_path)

          raise Errors::FatalException,
                "#{path}: entry '#{entry.key}' lists '#{file}', but #{file_path} does not exist"
        end
      end
    end
  end
end
