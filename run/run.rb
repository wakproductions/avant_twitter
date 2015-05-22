require_relative '../lib/avant_twitter'

at = AvantTwitter::AvantTwitter.new
at.process_stream
at.present_report

# Data processing
# 1. Word count of each tweet / total word count
# 2. Filter out "stop words" (words like "and", "the", "me", etc -- useless words)
# 3. Present the 10 most frequent words in those 5 minutes of tweets



### Overwrite code:

# loop do
#   time = Time.now.to_s + "\r"
#   print time
#   $stdout.flush
#   sleep 1
# end

