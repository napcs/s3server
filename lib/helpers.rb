module S3Server::Helpers

  def self.format_mb(size)
    conv = [ 'b', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB' ];
    scale = 1024;

    ndx = 1

    if( size < 2*(scale**ndx)  ) then
      return "#{(size)} #{conv[ndx-1]}"
    end

    size = size.to_f

    [2,3,4,5,6,7].each do |ndx|
      if( size < 2*(scale**ndx)  ) then
        return "#{'%.3f' % (size/(scale**(ndx-1)))} #{conv[ndx-1]}"
      end
    end

    ndx = 7

    return "#{'%.3f' % (size/(scale**(ndx-1)))} #{conv[ndx-1]}"
  end
end
