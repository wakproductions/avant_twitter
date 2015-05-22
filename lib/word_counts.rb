module AvantTwitter
  module WordCounts
    def initialize_word_counts(options)
      @word_counts = Hash.new
      @skip_words = options[:skip_words] if options.has_key? :skip_words # takes an array of words to skip
    end

    # Takes a string and splits it into words, the performs filtering on each word
    def process_words(tweet)
      tweet = tweet.downcase  # It's easier to format our report if we present every word in lower case.
      tweet = strip_emoji(tweet)
      tweet = strip_urls(tweet)
      tweet = strip_html_entities(tweet)
      tweet = strip_usernames(tweet)
      tweet = strip_numbers(tweet)

      tally_words(tweet)
    end

    def tally_words(sanitized_tweet)
      words = sanitized_tweet.scan /([#A-Za-z0-9'_-]+)\b/
      words.each do |match| # String#scan puts each word (match group) in an array, i.e. [["firstword"], ["secondword"], ["thirdword"]]
        word = match[0]
        unless @skip_words.index(word)
          word_sym = word.to_sym
          @word_counts.has_key?(word_sym) ? @word_counts[word_sym] += 1 : @word_counts[word_sym] = 1
        end
      end
    end

    def save_word_counts(file_path)
      puts "Saving word counts to #{file_path}"
      report_file_stream = open(file_path, 'w')
      begin
        @word_counts.each do |k,v|
          report_file_stream.write "#{k},#{v}\n"
        end
      ensure
        report_file_stream.close
      end
    end

    def sort_words!
      # To accomplish this we turn it into an array of key/value pairs, invoke the sort method, then rehash it
      word_array = @word_counts.to_a
      @word_counts = word_array.sort do |(k_1,v_1),(k_2,v_2)|
        # If both words occur the same number of times, then sort alphabetically
        if v_1 != v_2
          v_2 <=> v_1
        else
          k_1 <=> k_2
        end
      end.to_h
    end

    # sort_words! must be called prior to calling this in order for this to be accurate
    def top_x(number, &before_filter)
      if before_filter
        word_counts = yield(@word_counts)
      else
        word_counts = @word_counts
      end

      number = [number, word_counts.values.uniq.count].min
      top_values = word_counts.values.uniq[0..number-1]

      # When getting the top 10 words by occurrence, we might have some ties in which two different words both occur
      # the same number times. On a top 10 list you would want to list both words.
      result = Array.new
      top_values.each_with_index do |top_x_value, index|
        word_counts.select { |word,count| count == top_x_value }.each do |word, count|
          result << {
              place: index+1,
              word: word.to_s,
              count: count
          }
        end
      end

      result
    end

    def total_words
      @word_counts.values.inject(0) { |total, word_count| total + word_count }
    end

    private

    # For explanation see http://stackoverflow.com/questions/24672834/how-do-i-remove-emoji-from-string
    def strip_emoji(text)
      text.gsub /[\u{1F600}-\u{1F6FF}]/, ''
    end

    def strip_urls(text)
      text.gsub /https?:\/\/.*?($|\s)/, ''
    end

    def strip_html_entities(text)
      text.gsub /&[A-Za-z0-9]+;/, ''
    end

    def strip_usernames(text)
      text.gsub /@.*?($|\s)/, ''
    end

    # We don't want to tally numbers, like "I ate 5 hambugers" - we don't want the "5" because it's not a word
    def strip_numbers(text)
      text.gsub /\b([0-9]+)\b/, ''
    end
  end
end