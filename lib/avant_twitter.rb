require 'twitter'
require 'yaml'
require_relative 'word_counts'

module AvantTwitter
  class AvantTwitter
    include WordCounts

    def initialize
      load_settings
      initialize_word_counts(
          skip_words: @settings[:skip_words],
          report_file: File.join(root_dir, @settings[:report_file])
      )
    end

    def stream_parameters
      @stream_parameters.select { |k,v| !v.nil? }
    end

    def load_settings
      load_twitter_secrets

      settings = YAML.load_file(File.join(root_dir, 'config', 'settings.yml'))
      stream_parameters = settings['twitter_stream_parameters'] || Hash.new
      program_settings = settings['program_settings'] || Hash.new

      @settings = {
          seconds: program_settings['read_seconds'] || 60 * 5,  # default is 5 minutes if this setting is empty
          report_file: program_settings['report_file'],
          save_file: program_settings['save_file'],
          console_output: program_settings['console_output'],
          skip_words: program_settings['skip_words'].downcase.split, # convert to downcase for easier comparison
          report_top: program_settings['report_top'] || 10,
          report_hashtags: program_settings['report_hashtags']
      }

      @stream_parameters = {
          language: stream_parameters['language'],
          track: stream_parameters['track'],
          follow: stream_parameters['follow'],
          locations: stream_parameters['locations'],
          replies: stream_parameters['replies'],
      }
    end
    alias_method :reload_settings, :load_settings

    def process_stream
      read_twitter_sample_stream
      sort_words!
      save_word_counts(File.join(root_dir, @settings[:report_file])) if !@settings[:report_file].nil?
    end

    def read_twitter_sample_stream
      puts "Reading stream for #{@settings[:seconds]} seconds..."
      stop_time = Time.now + @settings[:seconds]

      open_save_file_stream if @settings[:save_file]
      begin
        @twitter.sample(stream_parameters) do |object|
          case object
            when Twitter::Tweet
              puts object.text if @settings[:console_output]
              @save_file_stream.write(object.text+"\n") if @settings[:save_file]
              process_words(object.text)

            when Twitter::Streaming::StallWarning
              puts object.message
              @save_file_stream.write(object.message+"\n") if @settings[:save_file]
          end
          break if Time.now > stop_time
        end
      rescue Exception => e
        puts "Error reading Twitter sample stream:\n#{e.message}"
      ensure
        @save_file_stream.close if @settings[:save_file]
      end

      puts "\n\nDone reading Twitter stream\n\n"
    end

    def present_report
      print_top_x_report("Word", top_x(@settings[:report_top]))
      print_total_words_report(total_words)

      if @settings[:report_hashtags]
        # Filter for only the hashtags
        top_x_hashtags = top_x(@settings[:report_top]) do |word_count_hash|
          word_count_hash.select { |word,count| word.to_s[0] == '#' && word.length > 1 }
        end
        print_top_x_report("Hashtag", top_x_hashtags)
      end
    end

    # If you notice, this method I consider to be "view" related and therefore don't make any calls to other
    # methods in the class. i.e. this method stands alone needing only its parameters and can easily be refactored
    # into a separate module. But I don't think such refactoring is necessary at this time.
    def print_top_x_report(report_subject, report_lines)
      if report_lines.count > 0
        puts "\n\nTop #{report_lines.last[:place]} #{report_subject}s by Occurence"
        puts "+-------+----------------------------------------+-------------+"
        puts "| Place | #{report_subject.ljust(39)}| Occurrences |"
        puts "+-------+----------------------------------------+-------------+"
        report_lines.each do |line|
          puts "|#{line[:place].to_s.rjust(6)} | #{line[:word].ljust(39)}|#{line[:count].to_s.rjust(12)} |"
        end
        puts "+-------+----------------------------------------+-------------+"

      else
        puts "No word counts recorded."
      end
    end

    def print_total_words_report(total_word_count)
      puts "Total number of words analyzed: #{total_word_count}"
    end

    private

    def root_dir
      File.expand_path(File.join(File.dirname(__FILE__), '../'))
    end

    def load_twitter_secrets
      secrets = YAML.load_file(File.join(root_dir, 'config', 'secrets.yml'))

      ['twitter_consumer_key','twitter_consumer_secret','twitter_access_token','twitter_access_token_secret'].each do |secret_name|
        if secrets[secret_name].nil?
          puts "Warning: #{secret_name} in secrets.yml is invalid. You need this setting if connecting to the Twitter sample API."
        end
      end

      @twitter = Twitter::Streaming::Client.new do |config|
        config.consumer_key        = secrets['twitter_consumer_key']
        config.consumer_secret     = secrets['twitter_consumer_secret']
        config.access_token        = secrets['twitter_access_token']
        config.access_token_secret = secrets['twitter_access_token_secret']
      end
    end

    def open_save_file_stream
      @save_file_stream = open(File.join(root_dir, @settings[:save_file]), 'w')
    end
  end
end
