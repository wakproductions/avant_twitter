A demo application using Twitter API to read a 5-minute stream of data and processing.

## Functional Requirements

As a quick tech evaluation I'd like you to use the Twitter streaming API (statuses/sample) to collect 5 minutes of tweets.
 Obtain a total word count, filter out "stop words" (words like "and", "the", "me", etc -- useless words),
 and present the 10 most frequent words in those 5 minutes of tweets. 

Please don't copy and paste any code, but of course you can do whatever research necessary.
 Your code should be clear to follow, with explanatory comments where necessary. 

Let me know if you have any questions about this (and also please confirm that you understand the project),
 and I look forward to seeing what you come up with!

Optional Part B) How would you implement it so that if you had to stop the program and restart,
 it could pick up from the total word counts that you started from?
 
### Acceptance Criteria

✅ Collects 5 minutes of Tweets (Bonus: The amount of time can be adjusted in the ```settings.yml``` file)

✅ Filters stop words (Bonus: The stop words can be changed in the ```settings.yml``` file) 

✅ Presents 10 most frequently used words (Bonus: You can adjust the number of places you would like to see in the ```settings.yml``` file)

✅ Presents a total word count

✅ Not implemented, but has structure to pick up total word count from last spot (see "Saving the Word Counts Report" below)
  
### Implementation Requirements

To use this gem, you need to register an application with Twitter and obtain a Consumer Key, Consumer Secret,
Access Token, and Access Token Secret. You then need to store those in the file ```config/secrets.yml``` in format
shown here:
 
    twitter_consumer_key:    <hidden-consumer-key>
    twitter_consumer_secret: <hidden-consumer-secret>
    access_token:            <hidden-token>
    access_token_secret:     <hidden-token-secret>
    
You can also change parameters of the stream being downloaded by adjusting the settings in the ```settings.yml``` file

### Running the Program

This program is a script intended to be run from the Terminal command line. To run this file, first make a local clone 
the Github repository. Then run bundler to install the dependencies:

    > bundle install
    
Then you can run the script by executing the file run.rb:

    > ruby run/run.rb
    
The program will then launch, read Twitter's API stream for 5 minutes, and then present a report of the top 10
most frequently used words. Some words may tie. For example, you can get a two words that were used 10 times each.
Therefore, the "top 10" list can have more than 10 words if you get several ties. Here is a sample report:

    Top 10 Occuring Words
    +-------+----------------------------------------+-------------+
    | Place | Word or Hashtag                        | Occurrences |
    +-------+----------------------------------------+-------------+
    |     1 | love                                   |         212 |
    |     2 | like                                   |         195 |
    |     3 | one                                    |         180 |
    |     4 | no                                     |         153 |
    |     5 | know                                   |         143 |
    |     6 | how                                    |         142 |
    |     7 | up                                     |         138 |
    |     8 | who                                    |         137 |
    |     9 | new                                    |         134 |
    |    10 | will                                   |         125 |
    +-------+----------------------------------------+-------------+
    Total number of words analyzed: 33048
    
## Notes & Special Features

### Saving the Twitter Stream

I initially tried using VCR to save the stream for later testing, but had some issues getting it to work because
the HTTPrb gem used by the Twitter gem does not seem to be supported by VCR. So as a quick alternative I decided
to just use a simple file stream and save the text portion of the tweets. The main use of this feature is to 
backtest the code performing the word count requirement and for analysis of the inputs in order to make better
filters. You can change the file name in ```settings.yml```


### Saving the Word Counts Report

As configured in ```settings.yml```, this program can save the word count tally to a file in comma separated value
format. Although not implemented, if this program were to continue counting from where it previously left off,
a routine could be embedded to read this file and load the values into the ```@word_counts``` hash upon initialization.

To check the quality of the data (to be sure it was sorting and filtering properly) I imported this file into excel
for analysis.

### Caveats

A reporting limitation is that for consistency of presentation all words are converted to lower case. So even names
will appear in lower case. i.e.) there's no mechanism to distinguish a proper nouns. Another limitation is that this
won't capture compound words, for instance "starship enterprise" it would consider as two separate words. This is in 
particular a problem for names like "Jennifer Aniston". One method we could use to fix this is creating a dictionary
of names. If this were an ongoing application we could use that dictionary to whitelist and filter special terms/names.

There may be a few outlier string phrases that aren't really words which can slip through the filters, but they should
be infrequent and are unlikely to appear in the "top 10" list of words. The filtering could be improved as these outliers
are found and analyzed. 

Some of the troublesome outliers that have not yet been fixed include words enclosed by quotes and some hyphenated words.

### Retweets

The spec does not say whether Retweets should be ignored. This implementation currently includes Retweets, but removes
the "RT" flag designating a Tweet as a Retweet. Retweets can throw off the data by double counting words. A popular 
Tweet that gets Retweeted many times can certainly skew the count of certain words. But depending on what we are trying
to do with this application, that behavior may or may not be desired. A setting could easily be created that decides
whether or not to filter Retweets based on the presence of "RT" in the Tweet text.

### What counts as a word?

Numbers, URLs, usernames, "RT" (retweet flags), and emoji do not count as words. Hashtags count as words. All punctuation
is filtered.

### Stop Word Filtering

In ```settings.yml``` there is a "skip_words" line where you can build a dictionary of words you want ignored.
 
### Hashtags Report

In ```settings.yml``` setting ```report_hashtags``` to true will generate an additional hashtags report. (I just found
this to be more interesting metadata.)