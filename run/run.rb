require_relative '../lib/avant_twitter'

at = AvantTwitter::AvantTwitter.new
at.process_stream
at.present_report

