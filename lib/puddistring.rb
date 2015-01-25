require 'open-uri'

# Module used to extend string with helper functions
module PuddiString
  # Trim a string, optionally adding a thing at the end.
  def trim(len)
    # Just call the other function.
    trim_cap(len, '')
  end
  def trim_ellipsis(len)
    # Special one for this hard to find character
    trim_cap(len, '…')
  end
  def trim_cap(len, cap)
    # Make sure inputs are the right type.
    len = len.to_i
    cap = cap.to_s
    # First, check if the string is already within the length.
    return self if length <= len
    # It's not, so find out how short we have to trim to.
    real_length = len - cap.length

    # Are we trimming to nothing?
    if real_length < 1
      # Does cap fit in remaining length?
      if cap.length == len
        return cap.extend PuddiString
      else
        return ''.extend PuddiString
      end
    end

    # Now just return the trimmed string (extended, of course)!
    (self[0...real_length] + cap).extend PuddiString
  end

  # Expand t.co urls inside of a string
  def expand_tcos(keep_trailing_slash = false)
    # Use keep_trailing_slash as a replacement variable.
    keep_trailing_slash = keep_trailing_slash ? '/' : ''

    @@puddistring_tco_expansion_hash ||= {}
    # Search for t.co urls.
    gsub(%r https?://t.co/\w+ i) do |url|
      # Load an expansion and save it.
      (@@puddistring_tco_expansion_hash[url] ||= URI(url).open(ssl_verify_mode: 0) { |io| io.base_uri.to_s }).gsub(/\/\z/, keep_trailing_slash) rescue url
    end
  end
end
