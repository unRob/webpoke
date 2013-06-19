#!/usr/bin/env ruby
#encoding: utf-8
#
#
# License
#
# DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE Version 2, December 2004
# 
# (C) 2012 Roberto Hidalgo un@rob.mx
# 
# Everyone is permitted to copy and distribute verbatim or modified copies of this license document, and changing it is allowed as long as the name is changed.
# 
# DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
# 
# You just DO WHAT THE FUCK YOU WANT TO.


class String
  
  def red
    "\033[41m\033[37m#{self}\033[0m"
  end
  
  def green
    "\033[42m\033[37m#{self}\033[0m"
  end
  
  def bold
    "\033[1m#{self}\033[0m";
  end
  
end

module Webpoke
  
  require 'httparty'
  require 'Webpoke/Class'
  require 'Webpoke/Config'
  require 'Webpoke/Test'
  
  $successes = 0;
  $errors = 0;
  $tested = 0;
  $tests = [];
  $log = ""
  $config = nil
  $groups = {};
  
  # Adds a test to the queue
  # @param block [Proc] the configuration for this test
  def test(&block)
    test = Test.new(&block)
    $tests << test
    return test
  end
  
    
  def group (groupName, description: nil)
    $groups[groupName] = {
      name: groupName,
      description: description,
      tests: []
    }
  end
  
  def args_for_test(test)
      
    if (!$config)
      $config = Webpoke::Config.new
    end
            
    args = {
      headers: $config.headers.merge(test.headers),
    }
    
    if test.data
      if $config.parse[:input]
        args[:body] = $config.parse[:input].call(test.data)
      else
        args[:data] = test.data
      end
    end
    
    if test.body
      args[:body] = test.body
    end
    
    args[:query] = test.query if test.query
    
    args
  end
  
  # Configures the poking
  # @param &block [Block] the configuration options
  # (see #Webpoke::Config)
  def config (&block)
    $config = Webpoke::Config.new(&block)
  end

  def run_test(test)
    
    $tested +=1
    fqu = if test.url.match(/^https?:\/\//i) then test.url; else $config.base+test.url; end
    args = args_for_test(test)
    
    log "#{$tested}: #{test.description}".bold
    log "#{test.method.upcase}: #{test.url}...", false
    $config.beforeSend(test.method, fqu, args) if $config.beforeSend
    
    begin
      r = HTTParty.send(test.method, fqu, args)
    rescue Interrupt
      puts Webpoke.results
      exit!
    rescue Exception => e
      raise Webpoke::TestHTTPError.new(e.message, e)
    end
    
    body = r.body
    begin
      if test.should_parse? && $config.parse[:output] && body.is_a?(String)
        body = $config.parse[:output].call(r.body)
      end
    rescue Exception => e
      raise Webpoke::TestParseError.new(e.message, body)
    end
    
    
    if test.passed?(r.code, body)
      true
    else
      if $config.on_failure
        log $config.on_failure.call(r.code, body)
      end
      false
    end
    
  end
  
  def gauge_success(test)
    begin
      success = run_test test
    rescue Webpoke::TestHTTPError => e
      log 'FAIL:'.red
      log e
      $errors += 1;
    rescue Webpoke::TestParseError => e
      log "Parsing failure: ".red
      log "\t#{e}"
      log "Data:"
      log "\t"+e.object
      $errors += 1;
    rescue Webpoke::TestSuccessError => e
      log "\nError while executing success for test".red
      log e
      log e.backtrace.join "\n"
    end
    
    if (success)
      $successes +=1
      log "OK!".green
      test.on_success.each do |dependent|
        dt = dependent.call()
        gauge_success dt
      end
    else
      $errors += 1
      log "FAIL!".red
    end
    return success
    
  end
  
  
  def run (group=nil)
    
    $tests.each do |test|
      next if group && test.group != group && !test.run_always
      
      next if test.dependant?
      next if test.did_run?
      
      gauge_success(test)
      
    end
      
  end
  
  
  def log (message, newLine=true)
    return true if $config.format != 'stdout'
    $stdout << message
    $stdout << "\n" if newLine
  end
  
  
  def Webpoke.document(group)
    
    groups = {}
    
    $tests.each do |test|
      return if group && !test.group == group
      
      if (!groups.has_key? test.group)
        groups[test.group] = $groups[test.group] || {tests:[], name: test.group}
      end
      
      groups[test.group][:tests] << test.describe
      
      test.on_success.each do |dp|
        dp.call()
      end
      
    end
    
    return JSON.pretty_generate groups.values
    
  end
  
  
  def Webpoke.results()
    
    if $config.format == 'stdout'
      puts "\nTests: #{Webpoke.tested}, success: #{Webpoke.success}, errors: #{Webpoke.failed}";
    else
      puts JSON.pretty_generate({
        tests: Webpoke.tested,
        success: Webpoke.success,
        errors: Webpoke.failed
        })
    end
    
    if (Webpoke.failed > 0)
      exit 1;
    else
      exit 0;
    end
    
  end
  
  def Webpoke.success
    return $successes
  end
  
  def Webpoke.failed
    return $errors
  end
  
  def Webpoke.tested
    return $tested
  end
  
  def Webpoke.formats
    return ['json', 'html', 'stdout']
  end
  
end