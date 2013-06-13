=begin rdoc
  A test
=end
class Webpoke::Test
  
  mark_accessible :description, :group, :url, :method, :success, :query, :should_fail, :headers, :data
  
  def initialize(&block)
    instance_eval(&block);
    @group = @group || ''
    @method = @method || 'get'
    @headers = @headers || {}
    
  end
  
  
  def default_success (code, body)
    if @should_fail
      return code > 399
    else
      return (200..202).include?(code)
    end
  end
  
  
  def success (&block)
    @success = block
  end
  
=begin rdoc
Returns the test description


=end
  def to_s
    @description
  end
  
  
  def pt(v)
    v = v.class.to_s
    case v
    when 'Fixnum'
      v = 'Int'
    when 'Hash'
      v = 'Object'
    when 'TrueClass', 'FalseClass'
      v = 'Boolean'
    end
    
    v.downcase
  end
  
=begin rdoc
  Returns the test description definition (so that we can auto-generate documentation)
=end  
  def describe
    
    query = []
    if (@query)
      @query.each do |k,v|
        query << {key: k, v:self.pt(v)}
      end
    end
    
    data = []
    if (@data)
      @data.each do |k,v|
        data << {key: k, v:self.pt(v)}
      end
    end
    
    return {
      description: @description,
      url: @url,
      method: @method,
      query: query,
      headers: @headers,
      data: data,
      sampleOutput: @sampleOutput
    }
    
  end
  
  
=begin rdoc
  Run the test
=end
  def passed? (response, body)
    
    if !self.default_success(response, body)
      return false
    end
    
    
    if @success
      begin
        result = @success.call(response, body)
      rescue Exception => e
        result = false
        Webpoke.log "\nError while executing success for test".red
        Webpoke.log e
        Webpoke.log e.backtrace.join "\n"
      end
    else
      result = self.default_success(response, body)
    end
    
    return result
    
  end
  
end

class Webpoke::TestError < StandardError
end