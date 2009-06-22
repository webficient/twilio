module Twilio
  # Twilio Verbs enable your application to respond to Twilio requests (to your app) with XML responses.
  # There are 5 primary verbs (say, play, gather, record, dial) and 3 secondary (hangup, pause, redirect).
  # Verbs can be chained and some nested.
  class Verb
    
    attr_reader :response
        
    def initialize(&block)
      @xml = Builder::XmlMarkup.new
      @xml.instruct!
      
      if block_given?
        @chain = true
        @response = @xml.Response { block.call(self) }
      end
    end
        
    # The Say verb converts text to speech that is read back to the caller. 
    # Say is useful for dynamic text that is difficult to prerecord. 
    #
    # Examples:
    #   Twilio::Verb.new.say('The time is 9:35 PM.')
    #   Twilio::Verb.new.say('The time is 9:35 PM.', :loop => 3)
    #
    # With numbers, 12345 will be spoken as "twelve thousand three hundred forty five" while
    # 1 2 3 4 5 will be spoken as "one two three four five."
    #
    #   Twilio::Verb.new.say('Your PIN is 1234', :loop => 4)
    #   Twilio::Verb.new.say('Your PIN is 1 2 3 4', :loop => 4)
    # 
    # If you need a longer pause between each loop, set the pause option:
    #
    #   Twilio::Verb.new.say('Your PIN is 1 2 3 4', :loop => 4, :pause => true)
    #
    # Options (see http://www.twilio.com/docs/api_reference/TwiML/say) are passed in as a hash:
    #
    #   Twilio::Verb.new.say('The time is 9:35 PM.', :voice => 'woman')
    #   Twilio::Verb.new.say('The time is 9:35 PM.', {:voice => 'woman', :language => 'es'})
    def say(*args)
      options = {:voice => 'man', :language => 'en', :loop => 1}
      args.each do |arg|
        case arg
        when String
          options[:text_to_speak] = arg
        when Hash
          options.merge!(arg)
        else
          raise ArgumentError, 'say expects String or Hash argument'
        end
      end
      
      output {
        if options[:pause]
          loop_with_pause(options[:loop], @xml) do
            @xml.Say(options[:text_to_speak], :voice => options[:voice], :language => options[:language])
          end
        else
          @xml.Say(options[:text_to_speak], :voice => options[:voice], :language => options[:language], :loop => options[:loop])
        end
      }
    end
    
    # The Play verb plays an audio URL back to the caller. 
    # Examples:
    #   Twilio::Verb.new.play('http://foo.com/cowbell.mp3')
    #   Twilio::Verb.new.play('http://foo.com/cowbell.mp3', :loop => 3)
    #
    # If you need a longer pause between each loop, set the pause option:
    #
    #   Twilio::Verb.new.play('http://foo.com/cowbell.mp3', :loop => 3, :pause => true)
    #
    # Options (see http://www.twilio.com/docs/api_reference/TwiML/play) are passed in as a hash,
    # but only 'loop' is currently supported.
    def play(*args)
      options = {:loop => 1}
      args.each do |arg|
        case arg
        when String
          options[:audio_url] = arg
        when Hash
          options.merge!(arg)
        else
          raise ArgumentError, 'play expects String or Hash argument'
        end
      end

      output {
        if options[:pause]
          loop_with_pause(options[:loop], @xml) do
            @xml.Play(options[:audio_url])
          end
        else
          @xml.Play(options[:audio_url], :loop => options[:loop])
        end          
      }
    end
    
    # The Gather verb collects digits entered by a caller into their telephone keypad. 
    # When the caller is done entering data, Twilio submits that data to a provided URL, 
    # as either a HTTP GET or POST request, just like a web browser submits data from an HTML form. 
    #
    # Options (see http://www.twilio.com/docs/api_reference/TwiML/gather) are passed in as a hash
    #
    # Examples:
    #   Twilio::Verb.new.gather
    #   Twilio::Verb.new.gather(:action => 'http://foobar.com')
    #   Twilio::Verb.new.gather(:finishOnKey => '*') 
    #   Twilio::Verb.new.gather(:action => 'http://foobar.com', :finishOnKey => '*') 
    def gather(*args, &block)
      options = args.shift
      output { @xml.Gather(options) }
    end
    
    # The Record verb records the caller's voice and returns a URL that links to a file 
    # containing the audio recording.
    #
    # Options (see http://www.twilio.com/docs/api_reference/TwiML/record) are passed in as a hash
    #
    # Examples:
    #   Twilio::Verb.new.record
    #   Twilio::Verb.new.record(:action => 'http://foobar.com')
    #   Twilio::Verb.new.record(:finishOnKey => '*') 
    #   Twilio::Verb.new.record(:transcribe => true, :transcribeCallback => '/handle_transcribe')
    def record(*args)
      options = args.shift
      output { @xml.Record(options) }
    end
    
    # The Dial verb connects the current caller to an another phone. If the called party picks up, 
    # the two parties are connected and can communicate until one hangs up. If the called party does 
    # not pick up, if a busy signal is received, or the number doesn't exist, the dial verb will finish.
    #
    # If an action verb is provided, Twilio will submit the outcome of the call attempt to the action URL. 
    # If no action is provided, Dial will fall through to the next verb in the document.
    #
    # Note: this is different than the behavior of Record and Gather. Dial does not submit back to the 
    # current document URL if no action is provided.
    #
    # Options (see http://www.twilio.com/docs/api_reference/TwiML/dial) are passed in as a hash
    #
    # Examples:
    #   Twilio::Verb.new.dial('415-123-4567')
    #   Twilio::Verb.new.dial('415-123-4567', :action => 'http://foobar.com')
    #   Twilio::Verb.new.dial('415-123-4567', {:timeout => 10, :callerId => '858-987-6543'}) 
    def dial(*args, &block)
      number_to_dial = ''
      options = {}
      args.each do |arg|
        case arg
        when String
          number_to_dial = arg
        when Hash
          options.merge!(arg)
        else
          raise ArgumentError, 'dial expects String or Hash argument'
        end
      end
      
      output { @xml.Dial(number_to_dial, options) }
    end
    
    # The Pause (secondary) verb waits silently for a number of seconds. 
    # It is normally chained with other verbs. 
    #
    # Options (see http://www.twilio.com/docs/api_reference/TwiML/pause) are passed in as a hash
    #
    # Examples:
    #   verb = Twilio::Verb.new { |v|
    #     v.say('greetings')
    #     v.pause(:length => 2)
    #     v.say('have a nice day')
    #   }
    #   verb.response
    def pause(*args)
      options = args.shift
      output { @xml.Pause(options) }
    end
    
    # The Redirect (secondary) verb transfers control to a different URL.
    # It is normally chained with other verbs.
    #
    # Options (see http://www.twilio.com/docs/api_reference/TwiML/redirect) are passed in as a hash
    #
    # Examples:
    #   verb = Twilio::Verb.new { |v|
    #     v.dial('415-123-4567')
    #     v.redirect('http://www.foo.com/nextInstructions')
    #   }
    #   verb.response
    def redirect(*args)
      redirect_to_url = ''
      options = {}
      args.each do |arg|
        case arg
        when String
          redirect_to_url = arg
        when Hash
          options.merge!(arg)
        else
          raise ArgumentError, 'dial expects String or Hash argument'
        end
      end
      
      output { @xml.Redirect(redirect_to_url, options) }
    end
    
    # The Hangup (secondary) verb ends the call. 
    # 
    # Examples:
    #   If your response is only a hangup:
    #
    #   Twilio::Verb.new.hangup
    #
    #   If your response is chained:
    #
    #   verb = Twilio::Verb.new { |v|
    #     v.say("The time is #{Time.now}")
    #     v.hangup
    #   }
    #   verb.response
    def hangup
      output { @xml.Hangup }
    end
          
    private
    
      def output
        @chain ? yield : @xml.Response { yield }
      end 
    
      def loop_with_pause(loop_count, xml, &verb_action)
        last_iteration = loop_count-1                               
        loop_count.times do |i|
          yield verb_action
          xml.Pause unless i == last_iteration
        end
      end
  end
end