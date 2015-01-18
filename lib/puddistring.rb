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
end
