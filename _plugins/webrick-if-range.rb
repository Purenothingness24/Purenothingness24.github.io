require 'webrick'

module Jekyll
  # `jekyll serve` runs on WEBrick, which answers a range request whose If-Range validator still matches with
  # 304 Not Modified instead of the range. A browser resuming a partly cached video then gets no data and reports a
  # format error, so videos stop playing on the local server. If-Range only chooses between sending the range (the
  # validator matches) and sending the whole file (it doesn't).
  module WEBrickIfRange
    def not_modified?(req, res, mtime, etag)
      if (validator = req['if-range'])
        req.header.delete('range') unless WEBrick::HTTPUtils.split_header_value(validator).include?(etag)
        req.header.delete('if-range')
      end
      super
    end
  end
end

WEBrick::HTTPServlet::DefaultFileHandler.prepend(Jekyll::WEBrickIfRange)
